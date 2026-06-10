# frozen_string_literal: true

module UseCases
  module Identity
    module Mfa
      class EnableTwoFactor < ::Core::BaseUseCase
        transactional!

        def initialize(
          service: ::Identity::MfaService.new
        )
          @service = service
        end

        # Menjalankan proses aktivasi MFA
        # @param user [Identity::User] User yang sedang login
        # @param otp_code [String] Kode TOTP untuk verifikasi aktivasi
        # @param password_challenge [String] Password saat ini untuk keamanan
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def perform_execute(user:, otp_code:, password_challenge:, tenant:)
          command = validate_with(::Identity::Commands::Mfa::EnableTwoFactorCommand, {
            password_challenge: password_challenge
          })
          return failure(command.error_messages, code: :validation_error) if command.failure?

          # 1. Verifikasi password saat ini
          unless user.authenticate(command.password_challenge)
            return failure("Kata sandi saat ini salah.", code: :invalid_password)
          end

          # 2. Konfirmasi dan aktifkan MFA via Service
          @service.enable_totp(user: user, code: otp_code)
        rescue StandardError => e
          Rails.logger.error "[Identity::Mfa::EnableTwoFactor] Error: #{e.message}"
          failure("Gagal mengaktifkan MFA.", code: :system_error)
        end
      end
    end
  end
end
