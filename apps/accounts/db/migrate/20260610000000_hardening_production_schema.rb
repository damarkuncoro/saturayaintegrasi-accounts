# frozen_string_literal: true

class HardeningProductionSchema < ActiveRecord::Migration[8.1]
  def change
    # 1. Clean up invalid/nil user_permissions records in DB (if any) before changing constraint
    reversible do |dir|
      dir.up do
        execute("DELETE FROM user_permissions WHERE permission_id IS NULL")
        execute("UPDATE roles SET system_defined = false WHERE system_defined IS NULL")
        execute("UPDATE role_permissions SET conditions = '{}'::jsonb WHERE conditions IS NULL")
      end
    end

    # 2. Foreign Key changes (restricting/preventing cascade for compliance and audit)
    # Add foreign key from users to tenants (no cascade)
    add_foreign_key :users, :tenants

    # Remove cascade foreign keys and replace them with standard (restrict) ones
    remove_foreign_key :login_attempts, :tenants
    add_foreign_key :login_attempts, :tenants

    remove_foreign_key :api_clients, :tenants
    add_foreign_key :api_clients, :tenants

    # 3. User Permissions Schema (Opsi A)
    change_column_null :user_permissions, :permission_id, false

    # Remove old index: index_user_permissions_on_user_resource_action
    remove_index :user_permissions, name: "index_user_permissions_on_user_resource_action"

    # Add new unique index: index_user_permissions_on_tenant_user_permission
    add_index :user_permissions, [ :tenant_id, :user_id, :permission_id ], unique: true, name: "index_user_permissions_on_tenant_user_permission"

    # 4. Null Constraint Small Patches
    change_column_null :roles, :system_defined, false, false
    change_column_null :role_permissions, :conditions, false, {}

    # 5. Missing Indekses (Operational Indexes)
    add_index :role_permissions, [ :tenant_id, :permission_id ], name: "index_role_permissions_on_tenant_permission"
    add_index :user_roles, [ :tenant_id, :role_id ], name: "index_user_roles_on_tenant_role"
    add_index :user_permissions, [ :permission_id ], name: "index_user_permissions_on_permission_id"
    add_index :api_clients, [ :tenant_id, :active ], name: "index_api_clients_on_tenant_active"
    add_index :api_clients, [ :tenant_id, :expires_at ], name: "index_api_clients_on_tenant_expires_at"

    # 6. Webhook retry fields & index
    add_column :webhook_deliveries, :attempt_count, :integer, default: 0, null: false
    add_column :webhook_deliveries, :next_retry_at, :datetime
    add_column :webhook_deliveries, :delivered_at, :datetime
    add_index :webhook_deliveries, [ :status, :next_retry_at ], name: "index_webhook_deliveries_on_status_next_retry"
  end
end
