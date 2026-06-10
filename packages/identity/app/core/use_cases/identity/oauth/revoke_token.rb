# frozen_string_literal: true

require "digest"
require "redis"

module UseCases
  module Identity
    module Oauth
      class RevokeToken
        class Result
          attr_reader :data, :error, :status

          def initialize(data: nil, error: nil, status: :ok)
            @data = data
            @error = error
            @status = status
          end

          def success?
            @error.nil?
          end
        end

        def initialize(params:)
          @params = params
        end

        def call
          token = @params[:token]
          if token.blank?
            return Result.new(error: "missing_token", status: :bad_request)
          end

          # 1. Cek apakah ini refresh token di DB
          token_digest = ::Identity::JwtRefreshToken.digest(token)
          refresh_token = ::Identity::JwtRefreshToken.find_by(token_digest: token_digest)
          if refresh_token
            refresh_token.update!(revoked_at: Time.current)
            return Result.new(data: { status: "revoked" })
          end

          # 2. Jika bukan refresh token, coba dekode sebagai JWT access token
          begin
            payload, _header = Services::Identity::JwksManager.decode_jwt(token)
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

          Result.new(data: { status: "revoked" })
        end
      end
    end
  end
end
