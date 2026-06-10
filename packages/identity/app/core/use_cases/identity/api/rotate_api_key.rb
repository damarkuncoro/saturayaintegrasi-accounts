# frozen_string_literal: true

module UseCases
  module Identity
    module Api
      class RotateApiKey < ::Core::BaseUseCase
        # Menjalankan proses rotasi key
        # @param client [Identity::ApiClient] Objek API Client yang akan dirotasi
        # @param tenant [System::Tenant] Tenant pemilik
        # @return [Core::Result]
        def execute(client:, tenant:)
          # 1. Generate new credentials
          new_key = "sk_#{SecureRandom.hex(24)}"
          new_secret = SecureRandom.hex(32)

          if client.update(api_key: new_key, api_secret: new_secret)
            # 2. Catat Audit Log
            audit_log(
              action: "api_key_rotated", 
              auditable: client, 
              tenant: tenant
            )

            # Kita kembalikan objek client, tapi perlu diingat secret hanya tersedia sekali
            success(client, meta: { raw_key: new_key, raw_secret: new_secret })
          else
            failure(client.errors.full_messages.to_sentence)
          end
        rescue => e
          Rails.logger.error "[Identity::Api::RotateApiKey] Error: #{e.message}"
          failure("Gagal merotasi API Key.")
        end
      end
    end
  end
end
