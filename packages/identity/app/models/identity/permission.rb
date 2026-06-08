# frozen_string_literal: true

module Identity
  class Permission < ApplicationRecord
    self.table_name = "permissions"
    include Normalizable

    has_many :role_permissions, class_name: "Identity::RolePermission", dependent: :destroy
    has_many :user_permissions, class_name: "Identity::UserPermission", dependent: :destroy

    validates :name, :slug, :resource_type, :action, presence: true
    validates :slug, uniqueness: true

    before_validation :normalize_fields

    private

    def normalize_fields
      self.slug = normalize_key(slug)
      self.resource_type = normalize_key(resource_type)
      self.action = normalize_key(action)
    end
  end
end
