module Identity
  class TrustedDevice < ApplicationRecord
    self.table_name = "trusted_devices"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped
    include Revocable
    include Normalizable
    include Auditable

    belongs_to :user, class_name: "Identity::User"

    before_validation :normalize_fields
    before_validation do
      self.tenant ||= user&.tenant
      self.last_verified_at ||= Time.current
    end

    validates :device_fingerprint_digest, presence: true
    validates :last_verified_at, presence: true

    # Override active scope to also check for expiration (30 days)
    scope :active, -> { where(revoked_at: nil).where("last_verified_at > ?", 30.days.ago) }

    private

    def normalize_fields
      self.device_fingerprint_digest = normalize_key(device_fingerprint_digest)
      self.revocation_reason = normalize_text(revocation_reason)
    end
  end
end
