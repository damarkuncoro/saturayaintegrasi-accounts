module Identity
  class UserConsent < ApplicationRecord
    self.table_name = "user_consents"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped
    include Revocable
    include Normalizable

    belongs_to :user, class_name: "Identity::User"
    belongs_to :sso_client_configuration, class_name: "Identity::SsoClientConfiguration"

    validates :granted_at, presence: true
    validates :consent_signature, presence: true
    validates :consented_scopes, presence: true
    validate :consented_scopes_format

    before_validation :assign_tenant_from_user

    private

    def assign_tenant_from_user
      self.tenant ||= user&.tenant
    end

    def consented_scopes_format
      unless consented_scopes.is_a?(Hash)
        errors.add(:consented_scopes, "harus bertipe Hash/JSON object")
      end
    end
  end
end
