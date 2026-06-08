# frozen_string_literal: true

module Identity
  class PasswordHistory < ApplicationRecord
    self.table_name = "password_histories"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped

    belongs_to :user, class_name: "Identity::User"

    validates :password_digest, presence: true
  end
end
