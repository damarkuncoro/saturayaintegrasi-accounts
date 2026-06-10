# frozen_string_literal: true

module UseCases
  module Identity
    module Mfa
      class DisableTwoFactor < ::Core::BaseUseCase
        transactional!

        def initialize(
          service: ::Identity::MfaService.new
        )
          @service = service
        end

        # Menjalankan proses deaktivasi MFA
        # @param user [Identity::User] User yang sedang login
        # @param otp_code [String] Kode TOTP untuk verifikasi
        # @param password_challenge [String] Password saat ini untuk keamanan
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def perform_execute(user:, otp_code:, password_challenge:, tenant:)
          command = validate_with(::Identity::Commands::Mfa::DisableTwoFactorCommand, {
            password_challenge: password_challenge
          })
          return failure(command.error_messages, code: :validation_error) if command.failure?

          @service.disable_mfa(
            user: user,
            password: command.password_challenge,
            otp_code: otp_code
          )
        rescue StandardError => e
          Rails.logger.error "[Identity::Mfa::DisableTwoFactor] Error: #{e.message}"
          failure("Terjadi kesalahan sistem.", code: :system_error)
        end
      end
    end
  end
end
