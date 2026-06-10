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
    validate :tenant_must_match_user_and_sso_client

    before_validation do
      self.tenant ||= user&.tenant if has_attribute?(:tenant_id)
    end

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

    private

    def tenant_must_match_user_and_sso_client
      return if tenant_id.blank? || user.blank? || sso_client_configuration.blank?

      errors.add(:user_id, "must belong to the same tenant") if user.tenant_id != tenant_id
      errors.add(:sso_client_configuration_id, "must belong to the same tenant") if sso_client_configuration.tenant_id != tenant_id
    end
  end
end
