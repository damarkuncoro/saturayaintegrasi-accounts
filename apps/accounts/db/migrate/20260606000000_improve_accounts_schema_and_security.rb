# frozen_string_literal: true

class ImproveAccountsSchemaAndSecurity < ActiveRecord::Migration[8.1]
  def change
    # 1. Soft Delete columns
    add_column :users, :deleted_at, :datetime
    add_index :users, [:tenant_id, :deleted_at]

    add_column :tenants, :deleted_at, :datetime
    add_index :tenants, :deleted_at

    # 2. Fix Foreign Keys to use cascade delete where appropriate
    # sessions -> users
    remove_foreign_key :sessions, :users
    add_foreign_key :sessions, :users, on_delete: :cascade

    # api_clients -> tenants
    remove_foreign_key :api_clients, :tenants
    add_foreign_key :api_clients, :tenants, on_delete: :cascade

    # user_permissions -> tenants
    remove_foreign_key :user_permissions, :tenants
    add_foreign_key :user_permissions, :tenants, on_delete: :cascade

    # user_permissions -> users
    remove_foreign_key :user_permissions, :users
    add_foreign_key :user_permissions, :users, on_delete: :cascade

    # 3. Add index for login throttling
    add_index :login_attempts, [:tenant_id, :success, :created_at], name: "index_login_attempts_on_throttle_check"

    # 4. Security: Rename device_fingerprint to digest for better security practice
    rename_column :trusted_devices, :device_fingerprint, :device_fingerprint_digest
  end
end
