module Identity
  class Session < ApplicationRecord
    self.table_name = "sessions"
    include TenantScoped
    include Revocable
    include Auditable
    
    belongs_to :user, class_name: "Identity::User"

    # Override active scope to also check for expiration
    scope :active, lambda {
      where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current)
    }

    before_validation do
      self.tenant ||= user&.tenant if has_attribute?(:tenant_id)
    end

    before_create do
      self.user_agent = System::Current.user_agent
      self.ip_address = System::Current.ip_address
    end
  end
end
