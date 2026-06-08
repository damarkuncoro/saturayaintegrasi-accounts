# frozen_string_literal: true

module UseCases
  module Identity
    class VerifyMfa
    def initialize(
      service: ::Identity::MfaService.new,
      audit_logger: Services::System::AuditLogger
    )
      @service = service
      @audit_logger = audit_logger
    end

    # Menjalankan proses verifikasi MFA
    # @param user [Identity::User] User yang mencoba login
    # @param otp_code [String] Kode TOTP dari user
    # @param tenant [System::Tenant] Tenant terkait
    # @param ip_address [String] Alamat IP request
    # @param user_agent [String] User agent request
    # @param remember_device [Boolean] Apakah akan mendaftarkan perangkat sebagai terpercaya
    # @return [Core::Result]
    def call(user:, otp_code:, tenant:, ip_address: nil, user_agent: nil, remember_device: false)
      # 1. Verifikasi Kode via Service
      result = @service.verify_login_code(user: user, code: otp_code, tenant: tenant)

      if result.success?
        # 2. Login Sukses - Buat Sesi
        session = create_session(user, tenant, ip_address, user_agent)
        
        user.reset_failed_attempts!
        user.update!(last_login_at: Time.current, last_login_ip: ip_address)

        # 3. Handle Trusted Device
        trusted_device_fingerprint_raw = nil
        if remember_device
          trusted_device_fingerprint_raw = "#{user_agent}-#{ip_address}"
          TrustDevice.new.call(
            user: user,
            fingerprint: trusted_device_fingerprint_raw,
            tenant: tenant,
            device_name: user_agent.to_s.truncate(50)
          )
        end
        
        @audit_logger.log(
          action: "mfa_login_success", 
          auditable: user, 
          tenant: tenant, 
          metadata: { session_id: session.id, remembered: remember_device, mfa_type: result.value }
        )

        Core::Result.success(user, meta: { session: session, trusted_device_fingerprint: trusted_device_fingerprint_raw })
      else
        # 3. Gagal Verifikasi
        @audit_logger.log(
          action: "mfa_login_failed", 
          auditable: user, 
          tenant: tenant,
          metadata: { ip_address: ip_address }
        )
        
        result
      end
    rescue => e
      Rails.logger.error "[Identity::VerifyMfa] Error: #{e.message}"
      Core::Result.failure("Terjadi kesalahan sistem saat verifikasi MFA.")
    end

    private

    def create_session(user, tenant, ip, ua)
      user.sessions.create!(
        tenant: tenant,
        ip_address: ip,
        user_agent: ua,
        expires_at: 24.hours.from_now
      )
    end
  end
end
end
