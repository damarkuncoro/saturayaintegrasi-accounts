class AddHashChainToAuditLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_logs, :previous_hash, :string
    add_column :audit_logs, :hash_signature, :string
    add_index :audit_logs, :hash_signature
  end
end
