# frozen_string_literal: true

module Identity
  class JwtRefreshToken < ApplicationRecord
    self.table_name = "jwt_refresh_tokens"

    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped

    belongs_to :user, class_name: "Identity::User"
    belongs_to :sso_client_configuration, class_name: "Identity::SsoClientConfiguration"
    belongs_to :replaced_by, class_name: "Identity::JwtRefreshToken", optional: true

    validates :token_digest, presence: true, uniqueness: true
    validates :family_id, presence: true
    validates :expires_at, presence: true

    scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

    def expired?
      expires_at <= Time.current
    end

    def revoked?
      revoked_at.present?
    end

    def active?
      !revoked? && !expired?
    end

    def self.digest(token)
      Digest::SHA256.hexdigest(token)
    end
  end
end
