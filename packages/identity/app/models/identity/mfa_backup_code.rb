# frozen_string_literal: true

module Identity
  class MfaBackupCode < ApplicationRecord
    self.table_name = "mfa_backup_codes"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped
    
    belongs_to :user, class_name: "Identity::User"

    validates :code_digest, presence: true, uniqueness: { scope: [:tenant_id, :user_id] }

    scope :unused, -> { where(used_at: nil) }
    scope :used, -> { where.not(used_at: nil) }

    def used?
      used_at.present?
    end

    def mark_used!
      update!(used_at: Time.current)
    end
  end
end
