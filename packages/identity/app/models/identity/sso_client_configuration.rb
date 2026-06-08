module Identity
  class SsoClientConfiguration < ApplicationRecord
    self.table_name = "sso_client_configurations"

    has_secure_password :client_secret, validations: false

    acts_as_tenant :tenant, class_name: "System::Tenant"
    include Normalizable

    validates :client_name, presence: true
    validates :client_id, presence: true, uniqueness: true
    validates :redirect_uris, presence: true
    validates :allowed_scopes, presence: true
    validates :active, inclusion: { in: [ true, false ] }
    validate :redirect_uris_format

    before_validation :normalize_fields
    before_validation :generate_client_credentials, on: :create

    scope :active, -> { where(active: true) }

    private

    def normalize_fields
      self.client_id = normalize_key(client_id)
      self.client_name = normalize_text(client_name)
      self.redirect_uris = normalize_array(redirect_uris)
      self.allowed_scopes = normalize_array(allowed_scopes)
    end

    def generate_client_credentials
      self.client_id ||= "client_#{SecureRandom.hex(16)}"
      if client_secret.blank? && client_secret_digest.blank?
        self.client_secret = "secret_#{SecureRandom.hex(32)}"
      end
    end

    def redirect_uris_format
      if redirect_uris.blank? || !redirect_uris.is_a?(Array)
        errors.add(:redirect_uris, "harus diisi dan berupa Array")
        return
      end

      redirect_uris.each do |uri_str|
        begin
          uri = URI.parse(uri_str)

          # Cegah skema berbahaya
          if %w[javascript data].include?(uri.scheme)
            errors.add(:redirect_uris, "mengandung skema berbahaya: #{uri.scheme}")
            next
          end

          # Validasi HTTPS atau localhost untuk keamanan production
          is_localhost = uri.host == "localhost" || uri.host == "127.0.0.1"
          unless uri.scheme == "https" || (is_localhost && uri.scheme == "http")
            errors.add(:redirect_uris, "harus menggunakan HTTPS (kecuali localhost): #{uri_str}")
            next
          end

          if uri.host.blank?
            errors.add(:redirect_uris, "mengandung URI tanpa host: #{uri_str}")
          end
        rescue URI::InvalidURIError
          errors.add(:redirect_uris, "mengandung URI yang tidak valid: #{uri_str}")
        end
      end
    end
  end
end
