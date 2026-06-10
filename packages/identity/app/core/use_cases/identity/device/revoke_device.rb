# frozen_string_literal: true

module UseCases
  module Identity
    module Device
      class RevokeDevice < ::Core::BaseUseCase
        # Menjalankan proses pencabutan perangkat terpercaya
        # @param device [Identity::TrustedDevice] Objek perangkat yang akan dicabut
        # @param revoked_by [Identity::User] User yang melakukan pencabutan
        # @param reason [String] Alasan pencabutan
        # @return [Core::Result]
        def perform_execute(device:, revoked_by:, reason: "user_request")
          if device.revoked?
            return success(device, meta: { message: "Perangkat sudah tidak aktif." })
          end

          if device.revoke!(by: revoked_by, reason: reason)
            # Catat Audit Log
            audit_log(
              action: "device_revoked", 
              auditable: device, 
              tenant: device.tenant,
              metadata: { reason: reason }
            )

            success(device)
          else
            failure("Gagal mencabut status terpercaya perangkat.")
          end
        rescue => e
          Rails.logger.error "[Identity::Device::RevokeDevice] Error: #{e.message}"
          failure("Terjadi kesalahan sistem saat mencabut perangkat.")
        end
      end
    end
  end
end
