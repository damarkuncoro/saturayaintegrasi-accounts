# frozen_string_literal: true

module Identity
  class ServiceClient < ApplicationRecord
    self.table_name = "service_clients"

    acts_as_tenant :tenant, class_name: "System::Tenant", optional: true
    include Normalizable

    has_secure_password :secret, validations: false

    validates :service_name, presence: true
    validates :client_id, presence: true, uniqueness: true
    validates :allowed_scopes, presence: true
    validates :active, inclusion: { in: [ true, false ] }

    before_validation :normalize_fields
    before_validation :generate_credentials, on: :create

    scope :active, -> { where(active: true) }

    def authenticate_client_secret(unencrypted_secret)
      authenticate_secret(unencrypted_secret)
    end

    private

    def normalize_fields
      self.client_id = normalize_key(client_id)
      self.service_name = normalize_text(service_name)
      self.allowed_scopes = normalize_array(allowed_scopes)
      self.allowed_ips = normalize_array(allowed_ips)
    end

    def generate_credentials
      self.client_id ||= "client_#{SecureRandom.hex(16)}"
      if secret.blank? && secret_digest.blank?
        self.secret = "secret_#{SecureRandom.hex(32)}"
      end
    end
  end
end
