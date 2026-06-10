# frozen_string_literal: true

module UseCases
  module Identity
    class ResetPasswordRequest
      include Normalizable

    def initialize(
      service: ::Identity::PasswordResetService.new,
      audit_logger: Services::System::AuditLogger
    )
      @service = service
      @audit_logger = audit_logger
    end

    # Menjalankan proses permintaan reset password
    # @param email [String] Email user yang meminta reset
    # @param tenant [System::Tenant] Tenant terkait
    # @param ip_address [String] Alamat IP request
    # @return [Core::Result]
    def execute(email:, tenant:, ip_address: nil)
      email = normalize_email(email)
      
      # Gunakan service untuk logika inti
      result = @service.request_reset(email: email, tenant: tenant)
      
      # Selalu beri pesan yang sama demi keamanan (pencegahan enumerasi email)
      Core::Result.success(result.value, meta: { message: "Instruksi reset kata sandi telah dikirim jika email terdaftar." })
    rescue => e
      Rails.logger.error "[Identity::ResetPasswordRequest] Error: #{e.message}"
      Core::Result.success(nil, meta: { message: "Instruksi reset kata sandi telah dikirim jika email terdaftar." })
    end
  end
end
end
