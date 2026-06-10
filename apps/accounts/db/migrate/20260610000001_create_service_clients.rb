# frozen_string_literal: true

class CreateServiceClients < ActiveRecord::Migration[8.1]
  def change
    create_table :service_clients, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :service_name, null: false
      t.string :client_id, null: false
      t.string :secret_digest, null: false
      t.string :allowed_scopes, default: [], array: true, null: false
      t.string :allowed_ips, default: [], array: true, null: false
      t.boolean :active, default: true, null: false
      t.uuid :tenant_id
      t.datetime :rotated_at

      t.timestamps
    end

    add_index :service_clients, :client_id, unique: true
    add_index :service_clients, :tenant_id
    add_foreign_key :service_clients, :tenants
  end
end
