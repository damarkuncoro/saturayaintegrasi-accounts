module SatuRayaCommons
  module InternalApiAuth
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_internal_request!
    end

    private

    def authenticate_internal_request!
      signature = request.headers["X-Internal-Signature"]
      payload   = request.headers["X-Internal-Payload"]
      secret    = ENV.fetch("HMAC_SECRET")

      unless SatuRayaCommons::Security::HmacSigner.verify?(payload, signature, secret)
        render_error(message: "Invalid internal signature", status: :unauthorized)
      end
    end
  end
end
