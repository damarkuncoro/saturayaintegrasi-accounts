module Identity
  class UserPermission < ApplicationRecord
    self.table_name = "user_permissions"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped
    include Normalizable

    belongs_to :user, class_name: "Identity::User"
    belongs_to :permission, class_name: "Identity::Permission", optional: true

    validates :resource_type, presence: true
  validates :action, presence: true
  validates :user_id, uniqueness: { scope: [ :resource_type, :action ], message: "has already been assigned this permission" }
  validate :tenant_must_match_user

  before_validation :normalize_fields

  def self.can?(user, action, resource_type)
    where(
      user: user,
      action: normalize_lookup_key(action),
      resource_type: normalize_lookup_key(resource_type)
    ).exists?
  end

  private

  def tenant_must_match_user
    return if tenant_id.blank? || user.blank?

    if user.tenant_id != tenant_id
      errors.add(:user_id, "must belong to the same tenant")
    end
  end

  def self.normalize_lookup_key(value)
    value.to_s.strip.downcase.presence
  end

  def normalize_fields
    self.resource_type = normalize_key(resource_type)
    self.action = normalize_key(action)
  end
end
end
