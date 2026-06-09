# frozen_string_literal: true

class CreateWebhooksTables < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_endpoints, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { to_table: :tenants }
      t.string :url, null: false
      t.string :secret, null: false
      t.string :events, array: true, default: [], null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    create_table :webhook_deliveries, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: { to_table: :tenants }
      t.references :webhook_endpoint, type: :uuid, null: false, foreign_key: { to_table: :webhook_endpoints }
      t.string :event_name, null: false
      t.jsonb :payload, default: {}, null: false
      t.string :status, default: "pending", null: false
      t.integer :response_code
      t.text :response_body
      t.integer :duration_ms
      t.string :error_message

      t.timestamps
    end
  end
end
