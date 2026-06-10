# frozen_string_literal: true

module Identity
  class PasswordHistory < ApplicationRecord
    self.table_name = "password_histories"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped

    belongs_to :user, class_name: "Identity::User"

    validates :password_digest, presence: true

    validate :tenant_must_match_user

    before_validation do
      self.tenant ||= user&.tenant if has_attribute?(:tenant_id)
    end

    private

    def tenant_must_match_user
      return if tenant_id.blank? || user.blank?

      if user.tenant_id != tenant_id
        errors.add(:user_id, "must belong to the same tenant")
      end
    end
  end
end
