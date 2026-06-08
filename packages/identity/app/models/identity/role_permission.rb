# frozen_string_literal: true

module Identity
  class RolePermission < ApplicationRecord
    self.table_name = "role_permissions"
    include TenantScoped

    belongs_to :role, class_name: "Identity::Role"
    belongs_to :permission, class_name: "Identity::Permission"

    validates :permission_id, uniqueness: { scope: :role_id }
  end
end
