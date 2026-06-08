# frozen_string_literal: true

module Identity
  class Role < ApplicationRecord
    self.table_name = "roles"
    include TenantScoped

    has_many :role_permissions, class_name: "Identity::RolePermission", dependent: :destroy
    has_many :permissions, through: :role_permissions, class_name: "Identity::Permission"
    has_many :user_roles, class_name: "Identity::UserRole", dependent: :destroy
    has_many :users, through: :user_roles, class_name: "Identity::User"

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: { scope: :tenant_id }

    before_validation :generate_slug, on: :create

    private

    def generate_slug
      self.slug ||= name.to_s.parameterize
    end
  end
end
