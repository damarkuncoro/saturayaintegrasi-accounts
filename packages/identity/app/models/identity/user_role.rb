# frozen_string_literal: true

module Identity
  class UserRole < ApplicationRecord
    self.table_name = "user_roles"
    include TenantScoped

    belongs_to :user, class_name: "Identity::User"
    belongs_to :role, class_name: "Identity::Role"

    validates :role_id, uniqueness: { scope: :user_id }
  end
end
