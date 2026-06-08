# frozen_string_literal: true

module Identity
  class EmailVerificationToken < ApplicationRecord
    self.table_name = "email_verification_tokens"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped
    include ExpirableToken

    belongs_to :user, class_name: "Identity::User"

    validates :token_digest, presence: true, uniqueness: true
    validates :expires_at, presence: true
  end
end
