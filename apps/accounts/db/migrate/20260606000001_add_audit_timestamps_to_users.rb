# frozen_string_literal: true

class AddAuditTimestampsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_verified_at, :datetime
    add_column :users, :disabled_at, :datetime
    add_column :users, :revoked_at, :datetime
    
    # Indexes for better lookup
    add_index :users, [:tenant_id, :email_verified_at]
    add_index :users, [:tenant_id, :disabled_at]
  end
end
