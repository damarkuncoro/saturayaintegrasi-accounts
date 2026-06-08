# frozen_string_literal: true

module UseCases
  module Identity
    class RevokeDevice
      def initialize(audit_logger: Services::System::AuditLogger)
        @audit_logger = audit_logger
      end

    # Menjalankan proses pencabutan perangkat terpercaya
    # @param device [Identity::TrustedDevice] Objek perangkat yang akan dicabut
    # @param revoked_by [Identity::User] User yang melakukan pencabutan
    # @param reason [String] Alasan pencabutan
    # @return [Core::Result]
    def call(device:, revoked_by:, reason: "user_request")
      if device.revoked?
        return Core::Result.success(device, meta: { message: "Perangkat sudah tidak aktif." })
      end

      if device.revoke!(by: revoked_by, reason: reason)
        # Catat Audit Log
        @audit_logger.log(
          action: "device_revoked", 
          auditable: device, 
          user: revoked_by,
          tenant: device.tenant,
          metadata: { reason: reason }
        )

        Core::Result.success(device)
      else
        Core::Result.failure("Gagal mencabut status terpercaya perangkat.")
      end
    rescue => e
      Rails.logger.error "[Identity::RevokeDevice] Error: #{e.message}"
      Core::Result.failure("Terjadi kesalahan sistem saat mencabut perangkat.")
    end
  end
end
end
