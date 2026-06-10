# frozen_string_literal: true

module UseCases
  module Identity
    class UpdatePassword
    def initialize(
      service: ::Identity::PasswordResetService.new,
      audit_logger: Services::System::AuditLogger
    )
      @service = service
      @audit_logger = audit_logger
    end

    # Menjalankan proses pembaruan password
    # @param token_digest [String] Token reset yang diberikan
    # @param password [String] Password baru
    # @param tenant [System::Tenant] Tenant terkait
    # @return [Core::Result]
    def execute(token_digest:, password:, tenant:)
      @service.reset_password(
        token_raw: token_digest, 
        new_password: password, 
        tenant: tenant
      )
    rescue => e
      Rails.logger.error "[Identity::UpdatePassword] Error: #{e.message}"
      Core::Result.failure("Gagal memperbarui kata sandi.")
    end
  end
end
end
