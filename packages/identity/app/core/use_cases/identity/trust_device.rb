# frozen_string_literal: true

module UseCases
  module Identity
    class TrustDevice
      def initialize(audit_logger: Services::System::AuditLogger)
        @audit_logger = audit_logger
      end

    # Menjalankan proses pendaftaran perangkat terpercaya
    # @param user [Identity::User] User pemilik perangkat
    # @param fingerprint [String] Fingerprint unik perangkat
    # @param device_name [String] Nama tampilan perangkat (opsional)
    # @param tenant [System::Tenant] Tenant terkait
    # @return [Core::Result]
    def execute(user:, fingerprint:, tenant:, device_name: nil)
      # 1. Cek apakah perangkat sudah terdaftar dan aktif
      digest = generate_digest(fingerprint)
      device = user.trusted_devices.for_tenant(tenant).active.find_by(device_fingerprint_digest: digest)
      
      if device
        return Core::Result.success(device, meta: { message: "Perangkat sudah terpercaya." })
      end

      # 2. Buat record perangkat baru
      device = user.trusted_devices.create(
        tenant: tenant,
        device_fingerprint_digest: digest,
        user_agent: device_name || "Perangkat Baru",
        last_verified_at: Time.current
      )

      if device.persisted?
        # 3. Catat Audit Log
        @audit_logger.log(
          action: "device_trusted", 
          auditable: device, 
          tenant: tenant,
          metadata: { device_name: device_name }
        )

        Core::Result.success(device)
      else
        Core::Result.failure(device.errors.full_messages.to_sentence)
      end
    rescue => e
      Rails.logger.error "[Identity::TrustDevice] Error: #{e.message}"
      Core::Result.failure("Gagal mendaftarkan perangkat terpercaya.")
    end

    private

    def generate_digest(fingerprint)
      Digest::SHA256.hexdigest(fingerprint.to_s)
    end
    end
  end
end
