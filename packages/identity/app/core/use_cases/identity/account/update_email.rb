# frozen_string_literal: true

module UseCases
  module Identity
    module Account
      class UpdateEmail < ::Core::BaseUseCase
        include Normalizable

        # Menjalankan proses pembaruan email
        # @param user [Identity::User] User yang sedang login
        # @param new_email [String] Email baru yang diinginkan
        # @param password_challenge [String] Password saat ini untuk verifikasi
        # @param tenant [System::Tenant] Tenant terkait
        # @return [Core::Result]
        def execute(user:, new_email:, password_challenge:, tenant:)
          # 1. Verifikasi password saat ini
          unless user.authenticate(password_challenge)
            return failure("Kata sandi saat ini salah.")
          end

          new_email = normalize_email(new_email)

          # 2. Cek apakah email sudah digunakan oleh user lain di tenant yang sama
          if tenant.users.where.not(id: user.id).exists?(email: new_email)
            return failure("Email sudah digunakan oleh pengguna lain.")
          end

          # 3. Update email (langsung atau via unconfirmed_email)
          # Di sini kita langsung update email namun set verified: false
          if user.update(email: new_email, email_verified_at: nil)
            # 4. Generate token verifikasi baru
            token_raw = SecureRandom.hex(32)
            token_digest = Digest::SHA256.hexdigest(token_raw)

            token = user.email_verification_tokens.create!(
              tenant: tenant,
              token_digest: token_digest,
              expires_at: 24.hours.from_now
            )

            # 5. Kirim email verifikasi ke email baru
            ::Identity::UserMailer.email_verification_instructions(user, token_raw).deliver_later

            # 6. Catat Audit Log
            audit_log(
              action: "email_updated", 
              auditable: user, 
              tenant: tenant,
              metadata: { new_email: new_email }
            )

            success(user)
          else
            failure(user.errors.full_messages.to_sentence)
          end
        rescue => e
          Rails.logger.error "[Identity::Account::UpdateEmail] Error: #{e.message}"
          failure("Gagal memperbarui email.")
        end
      end
    end
  end
end
