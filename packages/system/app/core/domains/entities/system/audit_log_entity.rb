# frozen_string_literal: true

require "digest"

module Domains
  module Entities
    module System
      class AuditLogEntity
        attr_accessor :id, :action, :user_id, :auditable_id, :auditable_type,
                      :tenant_id, :metadata, :audited_changes, :remote_ip,
                      :user_agent, :previous_hash, :hash_signature, :created_at

        def initialize(attrs = {})
          @id = attrs[:id]
          @action = attrs[:action]
          @user_id = attrs[:user_id]
          @auditable_id = attrs[:auditable_id]
          @auditable_type = attrs[:auditable_type]
          @tenant_id = attrs[:tenant_id]
          @metadata = attrs[:metadata] || {}
          @audited_changes = attrs[:audited_changes] || {}
          @remote_ip = attrs[:remote_ip]
          @user_agent = attrs[:user_agent]
          @previous_hash = attrs[:previous_hash]
          @hash_signature = attrs[:hash_signature]
          @created_at = attrs[:created_at] || Time.current
        end

        def sign!(prev_hash)
          self.previous_hash = prev_hash || "0" * 64
          data_to_hash = [
            previous_hash,
            action,
            user_id,
            auditable_id,
            auditable_type,
            metadata.to_json,
            created_at.to_i
          ].join("|")
          self.hash_signature = Digest::SHA256.hexdigest(data_to_hash)
        end

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
      end
    end
  end
end
