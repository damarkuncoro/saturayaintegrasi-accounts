# frozen_string_literal: true

module UseCases
  module Identity
    class ChangePassword
      def initialize(audit_logger: Services::System::AuditLogger)
        @audit_logger = audit_logger
      end

    # Menjalankan proses perubahan password
    # @param user [Identity::User] User yang sedang login
    # @param password [String] Password baru
    # @param password_challenge [String] Password saat ini (untuk verifikasi)
    # @param tenant [System::Tenant] Tenant terkait
    # @param revoke_others [Boolean] Apakah akan mencabut sesi lain
    # @return [Core::Result]
    def call(user:, password:, password_challenge:, tenant:, revoke_others: false)
      # 1. Verifikasi password saat ini
      unless user.authenticate(password_challenge)
        return Core::Result.failure("Kata sandi saat ini salah.")
      end

      # 2. Cek apakah password baru sama dengan password lama (Security best practice)
      if SatuRayaCommons::Security::PasswordHasher.verify?(password, user.password_digest)
        return Core::Result.failure("Kata sandi baru tidak boleh sama dengan kata sandi saat ini.")
      end

      # 3. Update password
      if user.update(password: password)
        # 4. Catat riwayat password
        user.password_histories.create!(
          tenant: tenant,
          password_digest: user.password_digest
        )

        # 5. Opsional: Cabut sesi lain
        if revoke_others
          user.sessions.active.where.not(id: System::Current.session&.id).each do |s|
            s.revoke!(reason: "password_changed")
          end
        end

        # 6. Catat Audit Log
        @audit_logger.log(
          action: "password_changed_by_user", 
          auditable: user, 
          tenant: tenant
        )

        Core::Result.success(user)
      else
        Core::Result.failure(user.errors.full_messages.to_sentence)
      end
    rescue => e
      Rails.logger.error "[Identity::ChangePassword] Error: #{e.message}"
      Core::Result.failure("Gagal mengubah kata sandi.")
    end
  end
end
end
