# frozen_string_literal: true

module Identity
  class MfaService
    def initialize(audit_logger: Services::System::AuditLogger)
      @audit_logger = audit_logger
    end

    # Mengaktifkan MFA (TOTP) untuk user
    def enable_totp(user:, code:)
      return Core::Result.failure("OTP secret belum disiapkan.") if user.otp_secret.blank?
      
      if user.verify_otp(code)
        Identity::User.transaction do
          user.update!(otp_required_for_login: true)
          backup_codes = user.generate_mfa_backup_codes!
          
          user.log_audit("mfa_enabled", metadata: { type: "totp" })
          
          Core::Result.success({ backup_codes: backup_codes })
        end
      else
        Core::Result.failure("Kode OTP tidak valid.")
      end
    rescue => e
      Core::Result.failure(e.message)
    end

    # Menonaktifkan MFA
    def disable_mfa(user:, password:, otp_code: nil)
      unless user.authenticate(password)
        return Core::Result.failure("Password tidak valid.")
      end

      if otp_code.present? && !user.verify_otp(otp_code)
        return Core::Result.failure("Kode OTP tidak valid.")
      end

      Identity::User.transaction do
        user.disable_2fa!
        user.log_audit("mfa_disabled")
      end

      Core::Result.success(user)
    rescue => e
      Core::Result.failure(e.message)
    end

    # Verifikasi kode MFA saat login
    def verify_login_code(user:, code:, tenant:)
      # Cek TOTP
      if user.verify_otp(code)
        return Core::Result.success(:totp)
      end

      # Cek Backup Code
      if user.verify_mfa_backup_code(code)
        return Core::Result.success(:backup_code)
      end

      Core::Result.failure("Kode MFA tidak valid.")
    end
  end
end
