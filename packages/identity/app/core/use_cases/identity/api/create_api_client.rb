# frozen_string_literal: true

module UseCases
  module Identity
    module Api
      class CreateApiClient < ::Core::BaseUseCase
        include Normalizable

        # Menjalankan proses pembuatan API Client
        # @param name [String] Nama client (misal: "Mobile App", "Internal Script")
        # @param tenant [System::Tenant] Tenant pemilik
        # @param rate_limit [Integer] Limit request per menit (default: 60)
        # @return [Core::Result]
        def execute(name:, tenant:, rate_limit: 60)
          client = ::Identity::ApiClient.new(
            tenant: tenant,
            name: normalize_text(name),
            rate_limit_per_minute: rate_limit
          )

          if client.save
            # Catat Audit Log
            audit_log(
              action: "api_client_created", 
              auditable: client, 
              tenant: tenant,
              metadata: { name: name, rate_limit: rate_limit }
            )

            success(client)
          else
            failure(client.errors.full_messages.to_sentence)
          end
        rescue => e
          Rails.logger.error "[Identity::Api::CreateApiClient] Error: #{e.message}"
          failure("Gagal membuat API Client.")
        end
      end
    end
  end
end
