module Identity
  class LoginAttempt < ApplicationRecord
    self.table_name = "login_attempts"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped
    include Normalizable
    include Auditable

    belongs_to :user, class_name: "Identity::User", optional: true

    before_validation :normalize_fields

    validates :email, presence: true

    private

    # Menstandarisasi email ke huruf kecil sebelum disimpan
    def normalize_fields
      self.email = normalize_email(email)
    end
  end
end
