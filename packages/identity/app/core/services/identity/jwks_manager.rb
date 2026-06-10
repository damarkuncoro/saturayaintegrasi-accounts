# frozen_string_literal: true

require "openssl"
require "base64"
require "digest"
require "jwt"
require "redis"

module Services
  module Identity
    module JwksManager
      def self.rsa_key
        @rsa_key ||= begin
          if ENV["JWT_PRIVATE_KEY"].present?
            OpenSSL::PKey::RSA.new(ENV["JWT_PRIVATE_KEY"])
          elsif Rails.application.credentials.jwt_private_key.present?
            OpenSSL::PKey::RSA.new(Rails.application.credentials.jwt_private_key)
          else
            key_file = Rails.root.join("tmp", "jwt_rsa.key")
            if File.exist?(key_file)
              OpenSSL::PKey::RSA.new(File.read(key_file))
            else
              FileUtils.mkdir_p(key_file.dirname)
              key = OpenSSL::PKey::RSA.generate(2048)
              File.write(key_file, key.to_pem)
              key
            end
          end
        end
      end

      def self.base64url_encode(str)
        Base64.urlsafe_encode64(str).tr("=", "")
      end

      def self.jwk
        @jwk ||= begin
          pub = rsa_key.public_key
          {
            kty: "RSA",
            alg: "RS256",
            use: "sig",
            kid: Digest::SHA256.hexdigest(pub.to_der)[0..15],
            n: base64url_encode(pub.n.to_s(2)),
            e: base64url_encode(pub.e.to_s(2))
          }
        end
      end

      def self.decode_jwt(token)
        if token.present?
          token_hash = Digest::SHA256.hexdigest(token)
          redis_url = ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
          redis = Redis.new(url: redis_url)
          if redis.get("oauth_blacklisted_token:#{token_hash}").present?
            raise JWT::DecodeError, "Token has been revoked"
          end
        end

        begin
          header = JWT.decode(token, nil, false)[1]
          algorithm = header["alg"]
        rescue
          algorithm = nil
        end

        if algorithm == "RS256"
          return JWT.decode(token, rsa_key.public_key, true, { algorithm: "RS256" })
        end

        keys = [ Rails.application.secret_key_base ]
        if ENV["JWT_SECRET_FALLBACKS"].present?
          keys += ENV["JWT_SECRET_FALLBACKS"].split(",").map(&:strip)
        end

        keys.each_with_index do |key, index|
          begin
            return JWT.decode(token, key, true, { algorithm: "HS256" })
          rescue JWT::DecodeError => e
            raise e if index == keys.length - 1
          end
        end
      end
    end
  end
end
