# frozen_string_literal: true

class AddReusedFieldsToJwtRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    change_table :jwt_refresh_tokens, bulk: true do |t|
      t.string :revocation_reason
      t.datetime :reused_detected_at
      t.string :reused_from_ip
      t.string :reused_user_agent
    end
  end
end
