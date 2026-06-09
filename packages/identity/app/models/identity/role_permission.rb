# frozen_string_literal: true

module Identity
  class RolePermission < ApplicationRecord
    self.table_name = "role_permissions"
    include TenantScoped

    belongs_to :role, class_name: "Identity::Role"
    belongs_to :permission, class_name: "Identity::Permission"

    validates :permission_id, uniqueness: { scope: :role_id }
    validate :tenant_must_match_role

    private

    def tenant_must_match_role
      return if tenant_id.blank? || role.blank?

      if role.tenant_id != tenant_id
        errors.add(:role_id, "must belong to the same tenant")
      end
    end
  end
end
