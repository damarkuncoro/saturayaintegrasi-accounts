# frozen_string_literal: true

module UseCases
  module Identity
    module Mfa
      class VerifyChallenge < ::Core::BaseUseCase
        transactional!

        def initialize(
          service: ::Identity::MfaService.new
        )
          @service = service
        end

        # Menjalankan proses verifikasi MFA
        # @param user [Identity::User] User yang mencoba login
        # @param code [String] Kode TOTP dari user
        # @param tenant [System::Tenant] Tenant terkait
        # @param ip_address [String] Alamat IP request
        # @param user_agent [String] User agent request
        # @param remember_device [Boolean] Apakah akan mendaftarkan perangkat sebagai terpercaya
        # @return [Core::Result]
        def perform_execute(user:, code:, tenant:, ip_address: nil, user_agent: nil, remember_device: false)
          validate_command = validate_with(::Identity::Commands::Mfa::VerifyChallengeCommand, {
            code: code
          })
          return failure(validate_command.error_messages, code: :validation_error) if validate_command.failure?
          if user.locked?
            return failure("Akun Anda sedang terkunci. Silakan hubungi admin atau reset kata sandi.")
          end

          # 1. Verifikasi Kode via Service
          result = @service.verify_login_code(user: user, code: validate_command.code, tenant: tenant)

          if result.success?
            # 2. Login Sukses - Buat Sesi
            session = create_session(user, tenant, ip_address, user_agent)

            user.reset_failed_attempts!
            user.update!(last_login_at: Time.current, last_login_ip: ip_address)

            # 3. Handle Trusted Device
            trusted_device_fingerprint_raw = nil
            if remember_device
              trusted_device_fingerprint_raw = "#{user_agent}-#{ip_address}"
              # Pastikan Use Case TrustDevice dipanggil dengan benar
              ::UseCases::Identity::Device::TrustDevice.new.execute(
                user: user,
                fingerprint: trusted_device_fingerprint_raw,
                tenant: tenant,
                device_name: user_agent.to_s.truncate(50)
              )
            end

            audit_log(
              action: "user_login",
              auditable: user,
              tenant: tenant,
              metadata: { session_id: session.id, remembered: remember_device, mfa_type: result.value }
            )

            success(user, meta: { session: session, trusted_device_fingerprint: trusted_device_fingerprint_raw })
          else
            # 3. Gagal Verifikasi
            user.record_failed_attempt!

            if user.failed_attempts >= 5
              user.lock!
              audit_log(action: "account_locked", auditable: user, tenant: tenant)
              result = failure("Akun Anda sedang terkunci. Silakan hubungi admin atau reset kata sandi.")
            end

            audit_log(
              action: "user_login_failed",
              auditable: user,
              tenant: tenant,
              metadata: { ip_address: ip_address }
            )

            result
          end
        rescue StandardError => e
          Rails.logger.error "[Identity::Mfa::VerifyChallenge] Error: #{e.message}"
          failure("Terjadi kesalahan sistem saat verifikasi MFA.")
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
end
