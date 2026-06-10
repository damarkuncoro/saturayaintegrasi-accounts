# frozen_string_literal: true

module UseCases
  module Identity
    module Auth
      class RevokeSession < ::Core::BaseUseCase
        transactional!

        # Menjalankan proses pencabutan sesi
        # @param session [Identity::Session] Objek sesi yang akan dicabut
        # @param revoked_by [Identity::User] User yang melakukan pencabutan (opsional)
        # @param reason [String] Alasan pencabutan (opsional, misal: "user_logout")
        # @return [Core::Result]
        def perform_execute(session:, revoked_by: nil, reason: "user_logout")
          if session.revoked?
            return success(session, meta: { message: "Sesi sudah tidak aktif." })
          end

          if session.revoke!(by: revoked_by, reason: reason)
            # Catat Audit Log
            audit_log(
              action: "session_revoked", 
              auditable: session, 
              tenant: session.tenant,
              metadata: { reason: reason }
            )

            success(session)
          else
            failure("Gagal mengakhiri sesi.")
          end
        rescue => e
          Rails.logger.error "[Identity::Auth::RevokeSession] Error: #{e.message}"
          failure("Terjadi kesalahan saat mengakhiri sesi.")
        end
      end
    end
  end
end
