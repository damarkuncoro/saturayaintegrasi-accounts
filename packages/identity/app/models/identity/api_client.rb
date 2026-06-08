module Identity
  class ApiClient < ApplicationRecord
    self.table_name = "api_clients"
    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped
    include Normalizable
    include Auditable
    has_secure_password :api_secret, validations: false

    validates :name, presence: true
    validates :api_key, presence: true, uniqueness: true
    validates :rate_limit_per_minute, presence: true, numericality: { greater_than: 0 }

    before_validation :normalize_fields
    before_validation :generate_credentials, on: :create

    private

    def normalize_fields
      self.api_key = normalize_key(api_key)
      self.name = normalize_text(name)
      self.allowed_ips = normalize_array(allowed_ips)
    end

    def generate_credentials
      self.api_key ||= "sr_#{SecureRandom.hex(24)}"
      
      if api_secret.blank? && api_secret_digest.blank?
        self.api_secret = SecureRandom.hex(32)
      end
    end
  end
end
