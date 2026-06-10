# frozen_string_literal: true

module UseCases
  module Identity
    module Oauth
      class RevokeToken
        attr_reader :params

        def initialize(params:)
          @params = params
        end

        # Mengeksekusi proses pencabutan token.
        # @return [Core::Result]
        def execute
          token = params[:token]
          if token.blank?
            return ::Core::Result.failure("missing_token", meta: { status: :bad_request })
          end

          # 1. Cek apakah ini refresh token di DB
          token_digest = ::Identity::JwtRefreshToken.digest(token)
          refresh_token = ::Identity::JwtRefreshToken.find_by(token_digest: token_digest)
          if refresh_token
            refresh_token.update!(revoked_at: Time.current)
            return ::Core::Result.success({ status: "revoked" }, meta: { status: :ok })
          end

          # 2. Jika bukan refresh token, coba dekode sebagai JWT access token
          begin
            payload, _header = jwks_manager.decode_jwt(token)
            exp = payload["exp"]
            ttl = exp - Time.current.to_i
            if ttl > 0
              token_hash = Digest::SHA256.hexdigest(token)
              redis_url = ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
              redis = Redis.new(url: redis_url)
              redis.setex("oauth_blacklisted_token:#{token_hash}", ttl, "1")
            end
          rescue JWT::DecodeError
            # Abaikan error jika token tidak valid/kadaluwarsa sesuai RFC 7009
          end

          ::Core::Result.success({ status: "revoked" }, meta: { status: :ok })
        end

        private

        def jwks_manager
          ::Services::Identity::JwksManager
        end
      end
    end
  end
end
