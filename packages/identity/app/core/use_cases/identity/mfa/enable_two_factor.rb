# frozen_string_literal: true

module UseCases
  module Identity
    module Mfa
      class EnableTwoFactor
        def initialize(
          service: ::Identity::MfaService.new,
          audit_logger: ::Services::System::AuditLogger
        )
          @service = service
          @audit_logger = audit_logger
        end

        # Menjalankan proses aktivasi MFA
        # @param user [Identity::User] User yang sedang login
        # @param otp_code [String] Kode TOTP untuk verifikasi aktivasi
        # @param password_challenge [String] Password saat ini untuk keamanan
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def execute(user:, otp_code:, password_challenge:, tenant:)
          # 1. Verifikasi password saat ini
          unless user.authenticate(password_challenge)
            return ::Core::Result.failure("Kata sandi saat ini salah.")
          end

          # 2. Konfirmasi dan aktifkan MFA via Service
          @service.enable_totp(user: user, code: otp_code)
        rescue StandardError => e
          Rails.logger.error "[Identity::Mfa::EnableTwoFactor] Error: #{e.message}"
          ::Core::Result.failure("Gagal mengaktifkan MFA.")
        end
      end
    end
  end
end
