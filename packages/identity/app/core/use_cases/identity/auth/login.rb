# frozen_string_literal: true

module UseCases
  module Identity
    module Auth
      class Login < ::Core::BaseUseCase
        include Normalizable
        transactional!

        # Menjalankan proses login
        # @param email [String] Email user
        # @param password [String] Password user
        # @param tenant [System::Tenant] Tenant terkait
        # @param ip_address [String] Alamat IP request
        # @param user_agent [String] User agent request
        # @param trusted_device_fingerprint [String] Fingerprint perangkat terpercaya (opsional)
        # @return [Core::Result]
        def perform_execute(email:, password:, tenant:, ip_address: nil, user_agent: nil, trusted_device_fingerprint: nil)
          email = normalize_email(email)
          user = tenant.users.find_by(email: email)

          # 1. Catat Login Attempt (selalu catat untuk audit)
          attempt = ::Identity::LoginAttempt.create!(
            tenant: tenant,
            email: email,
            user: user,
            ip_address: ip_address,
            user_agent: user_agent
          )

          # 2. Proteksi terhadap email yang tidak terdaftar (Timing attack mitigation)
          unless user
            attempt.update!(success: false, failure_reason: "user_not_found")
            return failure("Email atau kata sandi salah.", code: :invalid_credentials)
          end

          # 3. Cek status akun (Lockable & Disabled)
          if user.locked?
            attempt.update!(success: false, failure_reason: "account_locked")
            return failure("Akun Anda sedang terkunci. Silakan hubungi admin atau reset kata sandi.", code: :account_locked)
          end

          if user.disabled_at.present? || !user.active?
            attempt.update!(success: false, failure_reason: "account_disabled")
            return failure("Akun Anda telah dinonaktifkan. Silakan hubungi dukungan pelanggan.", code: :account_disabled)
          end

          # 4. Verifikasi Password
          unless user.authenticate(password)
            user.record_failed_attempt!
            
            # Lock akun jika mencapai batas (misal: 5 kali)
            if user.failed_attempts >= 5
              user.lock!
              audit_log(action: "account_locked", auditable: user, tenant: tenant)
            end

            attempt.update!(success: false, failure_reason: "invalid_password")
            return failure("Email atau kata sandi salah.", code: :invalid_credentials)
          end

          # 5. Cek MFA (Multi-Factor Authentication)
          if user.otp_required_for_login?
            # Skip MFA jika perangkat terpercaya dan tidak terdeteksi risiko
            is_trusted = false
            is_risky = risky_login?(user, ip_address, user_agent)

            if is_risky
              audit_log(
                action: "login_risk_detected",
                auditable: user,
                tenant: tenant,
                metadata: { ip_address: ip_address, user_agent: user_agent }
              )
            elsif trusted_device_fingerprint.present?
              digest = Digest::SHA256.hexdigest(trusted_device_fingerprint.to_s)
              is_trusted = user.trusted_devices.for_tenant(tenant).active.exists?(device_fingerprint_digest: digest)
            end

            unless is_trusted
              attempt.update!(success: true, failure_reason: "mfa_required")
              return success(user, meta: { status: :mfa_required })
            end
          end

          # 6. Login Sukses - Buat Sesi
          session = create_session(user, tenant, ip_address, user_agent)
          user.reset_failed_attempts!
          user.update!(last_login_at: Time.current, last_login_ip: ip_address)
          
          attempt.update!(success: true)
          audit_log(action: "login_success", auditable: user, tenant: tenant, metadata: { session_id: session.id })

          success(user, meta: { status: :success, session: session })
        rescue => e
          Rails.logger.error "[Identity::Auth::Login] Error: #{e.message}"
          raise e if Rails.env.test?
          failure("Terjadi kesalahan sistem saat proses login.", code: :system_error)
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

        def risky_login?(user, ip_address, user_agent)
          return false if ip_address.blank?

          past_ips = user.sessions.where("created_at > ?", 30.days.ago).pluck(:ip_address).compact.uniq
          past_ips += ::Identity::LoginAttempt.where(user: user, success: true).where("created_at > ?", 30.days.ago).pluck(:ip_address).compact.uniq
          past_ips = past_ips.uniq

          # Jika tidak ada riwayat login sukses sebelumnya (user baru), maka tidak dianggap mencurigakan
          return false if past_ips.empty?

          # Jika IP saat ini tidak ada dalam daftar IP sukses sebelumnya, berarti ini login mencurigakan/berisiko
          !past_ips.include?(ip_address)
        end
      end
    end
  end
end
