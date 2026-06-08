# frozen_string_literal: true

module UseCases
  module Identity
    class UpdateEmail
      include Normalizable

      def initialize(audit_logger: Services::System::AuditLogger)
        @audit_logger = audit_logger
      end

    # Menjalankan proses pembaruan email
    # @param user [Identity::User] User yang sedang login
    # @param new_email [String] Email baru yang diinginkan
    # @param password_challenge [String] Password saat ini untuk verifikasi
    # @param tenant [System::Tenant] Tenant terkait
    # @return [Core::Result]
    def call(user:, new_email:, password_challenge:, tenant:)
      # 1. Verifikasi password saat ini
      unless user.authenticate(password_challenge)
        return Core::Result.failure("Kata sandi saat ini salah.")
      end

      new_email = normalize_email(new_email)

      # 2. Cek apakah email sudah digunakan oleh user lain di tenant yang sama
      if tenant.users.where.not(id: user.id).exists?(email: new_email)
        return Core::Result.failure("Email sudah digunakan oleh pengguna lain.")
      end

      # 3. Update email (langsung atau via unconfirmed_email)
      # Di sini kita langsung update email namun set verified: false
      if user.update(email: new_email, verified: false)
        # 4. Generate token verifikasi baru
        token = user.email_verification_tokens.create!(
          tenant: tenant,
          token_digest: SecureRandom.hex(32),
          expires_at: 24.hours.from_now
        )

        # 5. Kirim email verifikasi ke email baru
        ::Identity::UserMailer.with(user: user, token: token.token_digest).email_verification.deliver_later

        # 6. Catat Audit Log
        @audit_logger.log(
          action: "email_updated", 
          auditable: user, 
          tenant: tenant,
          metadata: { new_email: new_email }
        )

        Core::Result.success(user)
      else
        Core::Result.failure(user.errors.full_messages.to_sentence)
      end
    rescue => e
      Rails.logger.error "[Identity::UpdateEmail] Error: #{e.message}"
      Core::Result.failure("Gagal memperbarui email.")
    end
  end
end
end
