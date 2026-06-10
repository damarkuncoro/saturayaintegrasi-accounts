# frozen_string_literal: true

module UseCases
  module Identity
    module Mfa
      class DisableTwoFactor
        def initialize(
          service: ::Identity::MfaService.new,
          audit_logger: ::Services::System::AuditLogger
        )
          @service = service
          @audit_logger = audit_logger
        end

        # Menjalankan proses deaktivasi MFA
        # @param user [Identity::User] User yang sedang login
        # @param otp_code [String] Kode TOTP untuk verifikasi
        # @param password_challenge [String] Password saat ini untuk keamanan
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def execute(user:, otp_code:, password_challenge:, tenant:)
          @service.disable_mfa(
            user: user,
            password: password_challenge,
            otp_code: otp_code
          )
        rescue StandardError => e
          Rails.logger.error "[Identity::Mfa::DisableTwoFactor] Error: #{e.message}"
          ::Core::Result.failure("Terjadi kesalahan sistem.")
        end
      end
    end
  end
end
