# frozen_string_literal: true

module Identity
  class AccountService
    def initialize(audit_logger: Services::System::AuditLogger)
      @audit_logger = audit_logger
    end

    # Menonaktifkan akun sementara (Admin atau User sendiri)
    def deactivate(user:, reason: nil)
      return Core::Result.failure("Akun sudah dinonaktifkan.") if user.disabled_at.present?

      Identity::User.transaction do
        user.update!(disabled_at: Time.current, active: false)
        
        # Cabut semua sesi aktif saat akun dinonaktifkan
        user.sessions.active.each { |s| s.revoke!(reason: "account_deactivated") }

        user.log_audit("account_deactivated", metadata: { reason: reason })
      end

      Core::Result.success(user)
    rescue => e
      Core::Result.failure(e.message)
    end

    # Mengaktifkan kembali akun
    def reactivate(user:)
      return Core::Result.failure("Akun sudah aktif.") if user.active? && user.disabled_at.nil?

      Identity::User.transaction do
        user.update!(disabled_at: nil, active: true)
        user.log_audit("account_reactivated")
      end

      Core::Result.success(user)
    rescue => e
      Core::Result.failure(e.message)
    end

    # Menghapus akun secara administratif (Soft Delete)
    def discard(user:, reason: nil)
      return Core::Result.failure("Akun sudah dihapus.") if user.discarded?

      Identity::User.transaction do
        user.discard
        user.update!(active: false)
        
        # Cabut semua sesi
        user.sessions.active.each { |s| s.revoke!(reason: "account_deleted") }

        user.log_audit("account_deleted", metadata: { reason: reason })
      end

      Core::Result.success(user)
    rescue => e
      Core::Result.failure(e.message)
    end
  end
end
