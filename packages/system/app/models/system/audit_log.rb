# frozen_string_literal: true

module System
  class AuditLog < ApplicationRecord
    self.table_name = "audit_logs"
    include Normalizable

    acts_as_tenant :tenant, class_name: "System::Tenant"
    include TenantScoped

    belongs_to :user, class_name: "Identity::User", optional: true
    belongs_to :auditable, polymorphic: true, optional: true

    validates :action, presence: true
    validate :tenant_must_match_user

    # Hash Chain for Tamper-Proof Logs
    before_create :sign_log

    before_validation :normalize_fields

    def self.log(action = nil, auditable: nil, metadata: {}, changes: {}, user: nil, tenant: nil, **options)
      ::Services::System::AuditLogger.log(
        action,
        auditable: auditable,
        metadata: metadata,
        changes: changes,
        user: user,
        tenant: tenant,
        **options
      )
    end

    # Memverifikasi integritas log ini terhadap previous_hash
    def verify_integrity!
      expected_data = [
        previous_hash,
        action,
        user_id,
        auditable_id,
        auditable_type,
        metadata.to_json,
        created_at.to_i
      ].join("|")

      hash_signature == Digest::SHA256.hexdigest(expected_data)
    end

    private

    def sign_log
      return if hash_signature.present?

      last_log = self.class.order(created_at: :desc, id: :desc).first
      self.previous_hash = last_log&.hash_signature || "0" * 64
      
      data_to_hash = [
        previous_hash,
        action,
        user_id,
        auditable_id,
        auditable_type,
        metadata.to_json,
        (created_at || Time.current).to_i
      ].join("|")

      self.hash_signature = Digest::SHA256.hexdigest(data_to_hash)
    end

    def normalize_fields
      self.action = normalize_key(action)
    end

    def tenant_must_match_user
      return if tenant_id.blank? || user.blank?

      if user.tenant_id != tenant_id
        errors.add(:user_id, "must belong to the same tenant")
      end
    end
  end
end
