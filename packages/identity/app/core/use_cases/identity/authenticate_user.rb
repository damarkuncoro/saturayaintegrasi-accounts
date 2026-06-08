module UseCases
  module Identity
  class AuthenticateUser
    def initialize(user_repository: Repositories::Identity::UserRepository.new, jwt_service: Services::Identity::JwtService)
      @user_repository = user_repository
      @jwt_service = jwt_service
    end

    def call(email:, password:, tenant:)
      user = @user_repository.find_by_email(email, tenant: tenant)

      return Core::Result.failure("Invalid email or password") unless user

      # Check if user is active and not disabled
      db_user = tenant.users.find_by(id: user.id)
      if db_user.nil? || !db_user.active? || db_user.disabled_at.present?
        return Core::Result.failure("Account is disabled")
      end

      unless valid_password?(user, password, tenant)
        return Core::Result.failure("Invalid email or password")
      end

      token = @jwt_service.generate(user)
      Core::Result.success(user, meta: { token: token })
    end

    private

    def valid_password?(user_entity, password, tenant)
      user = tenant.users.find_by(id: user_entity.id)
      user&.authenticate(password)
    end
  end
end
end
