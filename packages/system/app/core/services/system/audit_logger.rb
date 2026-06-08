module Services
  module System
  class AuditLogger
    # Mencatat aktivitas ke dalam ::System::AuditLog
    # @param action [String] Nama aksi (misal: "worker_assigned")
    # @param auditable [ActiveRecord::Base, Object] Objek yang diaudit
    # @param metadata [Hash] Data tambahan dalam format JSON
    # @param changes [Hash] Perubahan data (audited_changes)
    # @param user [::Identity::User] ::Identity::User yang melakukan aksi
    # @param tenant [::System::Tenant] ::System::Tenant terkait
    def self.log(action = nil, auditable: nil, metadata: {}, changes: {}, user: nil, tenant: nil, **options)
      action ||= options[:action]
      auditable ||= options[:auditable]
      metadata = options[:metadata] if options.key?(:metadata)
      changes = options[:changes] if options.key?(:changes)
      user ||= options[:user]
      tenant ||= options[:tenant]

      user ||= ::System::Current.user
      tenant ||= ::System::Current.tenant || (auditable.respond_to?(:tenant) ? auditable.tenant : nil)

      ::System::AuditLog.create!(
        action: action,
        auditable: auditable,
        tenant: tenant,
        user: user,
        metadata: metadata,
        audited_changes: changes,
        remote_ip: ::System::Current.ip_address,
        user_agent: ::System::Current.user_agent
      )
    rescue => e
      # Kita tidak ingin menghentikan proses utama jika audit log gagal
      Rails.logger.error "[AuditLogger] Gagal mencatat log: #{e.message}"
    end
  end
end

end