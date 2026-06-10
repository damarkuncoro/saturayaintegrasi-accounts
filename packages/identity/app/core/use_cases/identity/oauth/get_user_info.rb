# frozen_string_literal: true

module UseCases
  module Identity
    module Oauth
      class GetUserInfo
        attr_reader :request

        def initialize(request:)
          @request = request
        end

        # Mengeksekusi proses pengambilan informasi user berdasarkan Bearer token.
        # @return [Core::Result]
        def execute
          token = request.headers["Authorization"]&.split(" ")&.last
          return ::Core::Result.failure("missing_token", meta: { status: :unauthorized }) if token.blank?

          begin
            payload, _header = jwks_manager.decode_jwt(token)
            user = ::Identity::User.find(payload["sub"])

            ::Core::Result.success({
              sub: user.id.to_s,
              email: user.email,
              name: user.full_name,
              preferred_username: user.username,
              given_name: user.first_name,
              family_name: user.last_name,
              email_verified: user.email_verified?
            }, meta: { status: :ok })
          rescue JWT::DecodeError
            ::Core::Result.failure("invalid_token", meta: { status: :unauthorized })
          rescue ActiveRecord::RecordNotFound
            ::Core::Result.failure("user_not_found", meta: { status: :unauthorized })
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
