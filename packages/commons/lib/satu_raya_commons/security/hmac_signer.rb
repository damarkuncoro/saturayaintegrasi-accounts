require "openssl"

module SatuRayaCommons
  module Security
    class HmacSigner
      def self.sign(payload, secret)
        OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
      end

      def self.verify?(payload, signature, secret)
        expected = sign(payload, secret)
        ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
      end
    end
  end
end
