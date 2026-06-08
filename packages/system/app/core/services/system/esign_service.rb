module Services
  module System
  class EsignService
    # Generic interface for E-Signature providers
    def self.request_signature(contract)
      return { success: false, error: "::Recruitment::Contract already signed" } if contract.signed?

      # Mocking the process of document preparation
      doc_token = "MOCK_DOC_#{SecureRandom.hex(8)}"
      signing_url = "https://esign-provider.test/sign/#{doc_token}"

      contract.update!(
        status: :sent,
        esign_metadata: {
          request_id: SecureRandom.uuid,
          provider: "MockProvider",
          requested_at: Time.current,
          signing_url: signing_url,
          doc_token: doc_token
        }
      )

      { success: true, signing_url: signing_url, message: "Signature request sent successfully." }
    end

    def self.simulate_callback(contract, action: :signed)
      return { success: false, error: "Invalid action" } unless [ :signed, :declined ].include?(action)

      case action
      when :signed
        contract.update!(status: :signed, signed_at: Time.current)
      when :declined
        contract.update!(status: :declined)
      end

      { success: true, status: contract.status }
    end

    def self.check_status(contract)
      { status: contract.status, signed_at: contract.signed_at, metadata: contract.esign_metadata }
    end
  end
end
end