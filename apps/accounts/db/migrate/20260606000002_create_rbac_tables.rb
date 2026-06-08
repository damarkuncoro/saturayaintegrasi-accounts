# frozen_string_literal: true

class CreateRbacTables < ActiveRecord::Migration[8.1]
  def change
    # 1. Roles Table
    create_table :roles, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.string :description
      t.boolean :system_defined, default: false
      t.timestamps
    end
    add_index :roles, [:tenant_id, :slug], unique: true

    # 2. Permissions Table
    create_table :permissions, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false # e.g., 'jobs.create'
      t.string :resource_type, null: false # e.g., 'Job'
      t.string :action, null: false # e.g., 'create'
      t.string :description
      t.timestamps
    end
    add_index :permissions, :slug, unique: true

    # 3. Role Permissions (Join Table)
    create_table :role_permissions, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.uuid :role_id, null: false
      t.uuid :permission_id, null: false
      t.jsonb :conditions, default: {}
      t.timestamps
    end
    add_index :role_permissions, [:role_id, :permission_id], unique: true
    add_foreign_key :role_permissions, :roles, on_delete: :cascade
    add_foreign_key :role_permissions, :permissions, on_delete: :cascade

    # 4. User Roles (Join Table)
    create_table :user_roles, id: :uuid do |t|
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.uuid :role_id, null: false
      t.timestamps
    end
    add_index :user_roles, [:user_id, :role_id], unique: true
    add_foreign_key :user_roles, :users, on_delete: :cascade
    add_foreign_key :user_roles, :roles, on_delete: :cascade

    # 5. Update user_permissions table to include explicit overrides flag
    add_column :user_permissions, :is_override, :boolean, default: true
    add_column :user_permissions, :permission_id, :uuid
    add_foreign_key :user_permissions, :permissions, on_delete: :cascade
    
    # We keep resource_type and action in user_permissions for backward compatibility 
    # and quick lookups, but ideally they should link to permissions table.
  end
end
