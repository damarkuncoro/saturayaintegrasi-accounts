# frozen_string_literal: true

module UseCases
  module Identity
    class RevokeSession
      def initialize(audit_logger: Services::System::AuditLogger)
        @audit_logger = audit_logger
      end

    # Menjalankan proses pencabutan sesi
    # @param session [Identity::Session] Objek sesi yang akan dicabut
    # @param revoked_by [Identity::User] User yang melakukan pencabutan (opsional)
    # @param reason [String] Alasan pencabutan (opsional, misal: "user_logout")
    # @return [Core::Result]
    def execute(session:, revoked_by: nil, reason: "user_logout")
      if session.revoked?
        return Core::Result.success(session, meta: { message: "Sesi sudah tidak aktif." })
      end

      if session.revoke!(by: revoked_by, reason: reason)
        # Catat Audit Log
        @audit_logger.log(
          action: "session_revoked", 
          auditable: session, 
          user: revoked_by || session.user,
          tenant: session.tenant,
          metadata: { reason: reason }
        )

        Core::Result.success(session)
      else
        Core::Result.failure("Gagal mengakhiri sesi.")
      end
    rescue => e
      Rails.logger.error "[Identity::RevokeSession] Error: #{e.message}"
      Core::Result.failure("Terjadi kesalahan saat mengakhiri sesi.")
    end
  end
end
end
