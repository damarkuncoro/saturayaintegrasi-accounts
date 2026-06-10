# frozen_string_literal: true

module UseCases
  module Identity
    class CreateApiClient
      include Normalizable

      def initialize(audit_logger: Services::System::AuditLogger)
        @audit_logger = audit_logger
      end

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
        @audit_logger.log(
          action: "api_client_created", 
          auditable: client, 
          tenant: tenant,
          metadata: { name: name, rate_limit: rate_limit }
        )

        Core::Result.success(client)
      else
        Core::Result.failure(client.errors.full_messages.to_sentence)
      end
    rescue => e
      Rails.logger.error "[Identity::CreateApiClient] Error: #{e.message}"
      Core::Result.failure("Gagal membuat API Client.")
    end
  end
end
end
