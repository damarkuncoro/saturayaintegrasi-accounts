require "jwt"

module SatuRayaCommons
  module Security
    class JwtCodec
      def self.encode(payload, secret, expires_in = 24.hours)
        payload_with_exp = payload.merge(
          exp: expires_in.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        )
        JWT.encode(payload_with_exp, secret, "HS256")
      end

      def self.decode(token, secret)
        decoded = JWT.decode(token, secret, true, algorithm: "HS256")[0]
        HashWithIndifferentAccess.new(decoded)
      rescue JWT::DecodeError, JWT::ExpiredSignature
        nil
      end
    end
  end
end
