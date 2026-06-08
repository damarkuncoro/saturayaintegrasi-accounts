# frozen_string_literal: true

module Identity
  class PasswordResetToken < ApplicationRecord
    self.table_name = "password_reset_tokens"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped
    include ExpirableToken

    belongs_to :user, class_name: "Identity::User"

    validates :token_digest, presence: true, uniqueness: true
    validates :expires_at, presence: true
  end
end
