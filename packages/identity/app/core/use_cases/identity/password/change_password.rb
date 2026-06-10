# frozen_string_literal: true

module UseCases
  module Identity
    module Password
      class ChangePassword < ::Core::BaseUseCase
        transactional!

        # Menjalankan proses perubahan password
        # @param user [Identity::User] User yang sedang login
        # @param password [String] Password baru
        # @param password_challenge [String] Password saat ini (untuk verifikasi)
        # @param tenant [System::Tenant] Tenant terkait
        # @param revoke_others [Boolean] Apakah akan mencabut sesi lain
        # @return [Core::Result]
        def perform_execute(user:, password:, password_challenge:, tenant:, revoke_others: false)
          # 1. Verifikasi password saat ini
          unless user.authenticate(password_challenge)
            return failure("Kata sandi saat ini salah.", code: :invalid_password)
          end

          # 2. Cek apakah password baru sama dengan password lama (Security best practice)
          if SatuRayaCommons::Security::PasswordHasher.verify?(password, user.password_digest)
            return failure("Kata sandi baru tidak boleh sama dengan kata sandi saat ini.", code: :password_reused)
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
            audit_log(
              action: "password_changed_by_user", 
              auditable: user, 
              tenant: tenant
            )

            success(user)
          else
            failure(user.errors.full_messages.to_sentence, code: :validation_error)
          end
        rescue => e
          Rails.logger.error "[Identity::Password::ChangePassword] Error: #{e.message}"
          failure("Gagal mengubah kata sandi.", code: :system_error)
        end
      end
    end
  end
end
