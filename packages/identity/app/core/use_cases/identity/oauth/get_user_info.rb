# frozen_string_literal: true

module UseCases
  module Identity
    module Oauth
      class GetUserInfo < ::Core::BaseUseCase
        attr_reader :request

        def initialize(request:)
          @request = request
        end

        # Mengeksekusi proses pengambilan informasi user berdasarkan Bearer token.
        # @return [Core::Result]
        def execute
          token = request.headers["Authorization"]&.split(" ")&.last
          return failure("missing_token", meta: { status: :unauthorized }) if token.blank?

          begin
            payload, _header = jwks_manager.decode_jwt(token)
            user = ::Identity::User.find(payload["sub"])
            presenter = ::Identity::Presenters::UserPresenter.new(user)

            success(presenter.oidc_userinfo, meta: { status: :ok })
          rescue JWT::DecodeError
            failure("invalid_token", meta: { status: :unauthorized })
          rescue ActiveRecord::RecordNotFound
            failure("user_not_found", meta: { status: :unauthorized })
          end
        end

        private

        def jwks_manager
          ::Services::Identity::JwksManager
        end
      end
    end
  end
end
