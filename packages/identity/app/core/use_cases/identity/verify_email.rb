# frozen_string_literal: true

module UseCases
  module Identity
    class VerifyEmail
    def initialize(
      service: ::Identity::EmailVerificationService.new,
      audit_logger: Services::System::AuditLogger, 
      sync_service: SatuRayaIdentity.user_sync_publisher
    )
      @service = service
      @audit_logger = audit_logger
      @sync_service = sync_service
    end

    # Menjalankan proses verifikasi email
    # @param token_digest [String] Token verifikasi yang diberikan
    # @param tenant [System::Tenant] Tenant terkait
    # @return [Core::Result]
    def call(token_digest:, tenant:)
      result = @service.verify(token_raw: token_digest, tenant: tenant)
      
      if result.success?
        user = result.value
        # Sinkronisasi Data User (status verified berubah)
        @sync_service.call(action: "updated", user: user)
      end

      result
    rescue => e
      Rails.logger.error "[Identity::VerifyEmail] Error: #{e.message}"
      Core::Result.failure("Gagal memverifikasi email.")
    end
  end
end
end
