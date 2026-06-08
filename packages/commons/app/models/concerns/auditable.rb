# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable, class_name: "System::AuditLog"
  end

  def log_audit(action, user: nil, metadata: {})
    audit_logs.create!(
      action: action,
      user: user || System::Current.user,
      tenant: self.respond_to?(:tenant) ? self.tenant : System::Current.tenant,
      remote_ip: System::Current.ip_address,
      user_agent: System::Current.user_agent,
      audited_changes: saved_changes,
      metadata: metadata
    )
  end
end
