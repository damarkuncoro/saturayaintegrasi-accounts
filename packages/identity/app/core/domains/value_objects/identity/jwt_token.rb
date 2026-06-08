module Domains
  module ValueObjects
    module Identity
    class JwtToken
      attr_reader :value, :expires_at

      def initialize(value:, expires_at:)
        @value = value
        @expires_at = expires_at
      end

      def expired?
        Time.current > expires_at
      end

      def self.from_payload(payload, secret_key_base)
        new(
          value: JWT.encode(payload, secret_key_base, "HS256"),
          expires_at: Time.at(payload["exp"])
        )
      end
    end
  end
end

end