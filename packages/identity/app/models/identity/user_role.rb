# frozen_string_literal: true

module Identity
  class UserRole < ApplicationRecord
    self.table_name = "user_roles"
    include TenantScoped

    belongs_to :user, class_name: "Identity::User"
    belongs_to :role, class_name: "Identity::Role"

    validates :role_id, uniqueness: { scope: :user_id }
    validate :tenant_must_match_user_and_role

    private

    def tenant_must_match_user_and_role
      return if tenant_id.blank? || user.blank? || role.blank?

      errors.add(:user_id, "must belong to the same tenant") if user.tenant_id != tenant_id
      errors.add(:role_id, "must belong to the same tenant") if role.tenant_id != tenant_id
    end
  end
end
