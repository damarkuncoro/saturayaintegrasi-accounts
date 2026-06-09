# frozen_string_literal: true

module Repositories
  module System
    class AuditLogRepository
      class << self
        def save(entity)
          # Fetch the last log signature to sign the entity if it has not been signed yet
          unless entity.hash_signature.present?
            last_record = ::System::AuditLog.order(created_at: :desc, id: :desc).first
            prev_hash = last_record&.hash_signature || "0" * 64
            entity.sign!(prev_hash)
          end

          record = if entity.id
                     ::System::AuditLog.find_by(id: entity.id)
                   else
                     ::System::AuditLog.new
                   end

          return false unless record

          record.assign_attributes(
            action: entity.action,
            user_id: entity.user_id,
            auditable_id: entity.auditable_id,
            auditable_type: entity.auditable_type,
            tenant_id: entity.tenant_id,
            metadata: entity.metadata,
            audited_changes: entity.audited_changes,
            remote_ip: entity.remote_ip,
            user_agent: entity.user_agent,
            previous_hash: entity.previous_hash,
            hash_signature: entity.hash_signature,
            created_at: entity.created_at
          )

          # Save the record, which propagates the database-generated ID back to the entity
          record.save!
          entity.id = record.id
          true
        end

        def find(id)
          record = ::System::AuditLog.find_by(id: id)
          return nil unless record

          to_entity(record)
        end

        private

        def to_entity(record)
          Domains::Entities::System::AuditLogEntity.new(
            id: record.id,
            action: record.action,
            user_id: record.user_id,
            auditable_id: record.auditable_id,
            auditable_type: record.auditable_type,
            tenant_id: record.tenant_id,
            metadata: record.metadata,
            audited_changes: record.audited_changes,
            remote_ip: record.remote_ip,
            user_agent: record.user_agent,
            previous_hash: record.previous_hash,
            hash_signature: record.hash_signature,
            created_at: record.created_at
          )
        end
      end
    end
  end
end
