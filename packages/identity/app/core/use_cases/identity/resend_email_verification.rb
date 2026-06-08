# frozen_string_literal: true

module UseCases
  module Identity
    class ResendEmailVerification
    def initialize(
      service: ::Identity::EmailVerificationService.new,
      audit_logger: Services::System::AuditLogger
    )
      @service = service
      @audit_logger = audit_logger
    end

    # Menjalankan proses pengiriman ulang email verifikasi
    # @param user [Identity::User] User yang meminta verifikasi ulang
    # @param tenant [System::Tenant] Tenant terkait
    # @return [Core::Result]
    def call(user:, tenant:)
      @service.send_verification(user: user)
    rescue => e
      Rails.logger.error "[Identity::ResendEmailVerification] Error: #{e.message}"
      Core::Result.failure("Gagal mengirim ulang email verifikasi.")
    end
    end
  end
end
