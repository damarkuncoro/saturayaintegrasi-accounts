# frozen_string_literal: true

class CreateJwtRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :jwt_refresh_tokens, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.uuid :sso_client_configuration_id, null: false
      t.string :token_digest, null: false
      t.uuid :family_id, null: false
      t.string :scopes, default: [], array: true, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.uuid :replaced_by_id
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :jwt_refresh_tokens, :token_digest, unique: true
    add_index :jwt_refresh_tokens, :family_id
    add_index :jwt_refresh_tokens, [ :tenant_id, :user_id ]

    add_foreign_key :jwt_refresh_tokens, :tenants, on_delete: :cascade
    add_foreign_key :jwt_refresh_tokens, :users, on_delete: :cascade
    add_foreign_key :jwt_refresh_tokens, :sso_client_configurations, on_delete: :cascade
    add_foreign_key :jwt_refresh_tokens, :jwt_refresh_tokens, column: :replaced_by_id, on_delete: :nullify
  end
end
