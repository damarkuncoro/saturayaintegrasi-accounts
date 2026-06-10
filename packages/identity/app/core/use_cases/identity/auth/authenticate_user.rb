# frozen_string_literal: true

module UseCases
  module Identity
    module Auth
      class AuthenticateUser < ::Core::BaseUseCase
        def initialize(user_repository: ::Repositories::Identity::UserRepository.new, jwt_service: ::Services::Identity::JwtService)
          @user_repository = user_repository
          @jwt_service = jwt_service
        end

        def perform_execute(email:, password:, tenant:)
          user = @user_repository.find_by_email(email, tenant: tenant)

          return failure("Invalid email or password", code: :invalid_credentials) unless user

          # Check if user is active and not disabled
          if !user.active? || user.disabled?
            return failure("Account is disabled", code: :account_disabled)
          end

          unless user.authenticate(password)
            return failure("Invalid email or password", code: :invalid_credentials)
          end

          token = @jwt_service.generate(user)
          success(user, meta: { token: token })
        end
      end
    end
  end
end
