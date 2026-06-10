# frozen_string_literal: true

class AccountsSchemaBaseline < ActiveRecord::Migration[8.1]
  def change
    # Enable extensions
    enable_extension "pg_catalog.plpgsql"
    enable_extension "pgcrypto"

    # 1. Tenants Table
    create_table "tenants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.boolean "active", default: true, null: false
      t.string "domain"
      t.string "name", null: false
      t.string "plan", default: "starter", null: false
      t.jsonb "settings", default: {}, null: false
      t.string "slug", null: false
      t.datetime "deleted_at"
      t.timestamps

      t.index "lower((domain)::text)", name: "index_tenants_on_lower_domain", unique: true, where: "(domain IS NOT NULL)"
      t.index "lower((slug)::text)", name: "index_tenants_on_lower_slug", unique: true
      t.index [ "deleted_at" ], name: "index_tenants_on_deleted_at"
    end

    # 2. Users Table
    create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.boolean "active", default: true, null: false
      t.string "email", null: false
      t.string "unconfirmed_email"
      t.string "first_name", default: "", null: false
      t.string "last_name", default: "", null: false
      t.boolean "otp_required_for_login", default: false, null: false
      t.string "otp_secret"
      t.string "password_digest", null: false
      t.string "phone", default: "", null: false
      t.string "provider"
      t.integer "role", default: 0, null: false
      t.uuid "tenant_id", null: false
      t.string "uid"
      t.string "username"
      t.boolean "verified", default: false, null: false
      t.integer "failed_attempts", default: 0, null: false
      t.datetime "locked_at"
      t.datetime "last_login_at"
      t.string "last_login_ip"
      t.datetime "deleted_at"
      t.datetime "email_verified_at"
      t.datetime "disabled_at"
      t.timestamps

      t.index "tenant_id, lower((email)::text)", name: "index_users_on_tenant_id_and_lower_email", unique: true
      t.index "tenant_id, lower((unconfirmed_email)::text)", name: "index_users_on_tenant_id_and_lower_unconfirmed_email", unique: true, where: "(unconfirmed_email IS NOT NULL)"
      t.index "tenant_id, lower((username)::text)", name: "index_users_on_tenant_id_and_lower_username", unique: true, where: "(username IS NOT NULL)"
      t.index [ "tenant_id", "active" ], name: "index_users_on_tenant_id_and_active"
      t.index [ "tenant_id", "deleted_at" ], name: "index_users_on_tenant_id_and_deleted_at"
      t.index [ "tenant_id", "disabled_at" ], name: "index_users_on_tenant_id_and_disabled_at"
      t.index [ "tenant_id", "email_verified_at" ], name: "index_users_on_tenant_id_and_email_verified_at"
      t.index [ "tenant_id", "provider", "uid" ], name: "index_users_on_tenant_provider_uid", unique: true, where: "((provider IS NOT NULL) AND (uid IS NOT NULL))"
      t.index [ "tenant_id", "role" ], name: "index_users_on_tenant_id_and_role"
      t.index [ "tenant_id", "verified" ], name: "index_users_on_tenant_id_and_verified"
    end

    # 3. API Clients Table
    create_table "api_clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.boolean "active", default: true, null: false
      t.string "allowed_ips", default: [], array: true
      t.string "api_key", null: false
      t.string "api_secret_digest", null: false
      t.datetime "expires_at"
      t.datetime "last_used_at"
      t.string "last_used_ip"
      t.string "name", null: false
      t.jsonb "permissions", default: {}, null: false
      t.integer "rate_limit_per_minute", default: 60, null: false
      t.uuid "tenant_id", null: false
      t.datetime "revoked_at"
      t.uuid "revoked_by_id"
      t.string "revocation_reason"
      t.timestamps

      t.index [ "api_key" ], name: "index_api_clients_on_api_key", unique: true
      t.index [ "tenant_id" ], name: "index_api_clients_on_tenant_id"
      t.index [ "revoked_by_id" ], name: "index_api_clients_on_revoked_by_id"
      t.index [ "tenant_id", "active", "revoked_at" ], name: "index_api_clients_on_tenant_active_revoked"
      t.index [ "tenant_id", "expires_at" ], name: "index_api_clients_on_tenant_expires_at"
    end

    # 4. Audit Logs Table
    create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "action", null: false
      t.uuid "auditable_id"
      t.string "auditable_type"
      t.jsonb "audited_changes", default: {}, null: false
      t.string "hash_signature"
      t.jsonb "metadata", default: {}, null: false
      t.string "previous_hash"
      t.string "remote_ip"
      t.string "request_id"
      t.uuid "tenant_id", null: false
      t.string "user_agent"
      t.uuid "user_id"
      t.timestamps

      t.index [ "auditable_type", "auditable_id" ], name: "index_audit_logs_on_auditable"
      t.index [ "hash_signature" ], name: "index_audit_logs_on_hash_signature"
      t.index [ "request_id" ], name: "index_audit_logs_on_request_id"
      t.index [ "tenant_id", "created_at" ], name: "index_audit_logs_on_tenant_and_created"
      t.index [ "user_id" ], name: "index_audit_logs_on_user_id"
      t.index [ "tenant_id", "action", "created_at" ], name: "index_audit_logs_on_tenant_action_created"
      t.index [ "tenant_id", "auditable_type", "auditable_id", "created_at" ], name: "index_audit_logs_on_tenant_auditable_created"
    end

    # 5. Email Verification Tokens Table
    create_table "email_verification_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.datetime "expires_at", null: false
      t.uuid "tenant_id", null: false
      t.string "token_digest", null: false
      t.datetime "used_at"
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "tenant_id", "user_id", "used_at" ], name: "index_email_verification_tokens_on_tenant_user_used"
      t.index [ "token_digest" ], name: "index_email_verification_tokens_on_token_digest", unique: true
      t.index [ "user_id" ], name: "index_email_verification_tokens_on_user_id"
      t.index [ "expires_at" ], name: "index_email_verification_tokens_on_expires_at"
    end

    # 6. Login Attempts Table
    create_table "login_attempts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "email", null: false
      t.string "failure_reason"
      t.string "ip_address"
      t.boolean "success", default: false, null: false
      t.uuid "tenant_id", null: false
      t.string "user_agent"
      t.uuid "user_id"
      t.timestamps

      t.index "tenant_id, lower((email)::text), created_at", name: "index_login_attempts_on_tenant_lower_email_created"
      t.index [ "ip_address", "created_at" ], name: "index_login_attempts_on_ip_and_created"
      t.index [ "tenant_id", "success", "created_at" ], name: "index_login_attempts_on_throttle_check"
      t.index [ "user_id" ], name: "index_login_attempts_on_user_id"
    end

    # 7. MFA Backup Codes Table
    create_table "mfa_backup_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "code_digest", null: false
      t.uuid "tenant_id", null: false
      t.datetime "used_at"
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "tenant_id", "user_id", "code_digest" ], name: "index_mfa_backup_codes_unique_digest_per_user", unique: true
      t.index [ "tenant_id", "user_id", "used_at" ], name: "index_mfa_backup_codes_on_tenant_user_used"
      t.index [ "user_id" ], name: "index_mfa_backup_codes_on_user_id"
    end

    # 8. Password Histories Table
    create_table "password_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "password_digest", null: false
      t.uuid "tenant_id", null: false
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "tenant_id", "user_id", "created_at" ], name: "index_password_histories_on_tenant_user_created"
      t.index [ "user_id" ], name: "index_password_histories_on_user_id"
    end

    # 9. Password Reset Tokens Table
    create_table "password_reset_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.datetime "expires_at", null: false
      t.string "request_ip"
      t.uuid "tenant_id", null: false
      t.string "token_digest", null: false
      t.datetime "used_at"
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "tenant_id", "user_id", "used_at" ], name: "index_password_reset_tokens_on_tenant_user_used"
      t.index [ "token_digest" ], name: "index_password_reset_tokens_on_token_digest", unique: true
      t.index [ "user_id" ], name: "index_password_reset_tokens_on_user_id"
      t.index [ "expires_at" ], name: "index_password_reset_tokens_on_expires_at"
    end

    # 10. Permissions Table
    create_table "permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "action", null: false
      t.string "description"
      t.string "name", null: false
      t.string "resource_type", null: false
      t.string "slug", null: false
      t.timestamps

      t.index [ "slug" ], name: "index_permissions_on_slug", unique: true
    end

    # 11. Roles Table
    create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "description"
      t.string "name", null: false
      t.string "slug", null: false
      t.boolean "system_defined", default: false, null: false
      t.uuid "tenant_id", null: false
      t.timestamps

      t.index [ "tenant_id", "slug" ], name: "index_roles_on_tenant_id_and_slug", unique: true
    end

    # 12. Role Permissions Table
    create_table "role_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.jsonb "conditions", default: {}, null: false
      t.uuid "permission_id", null: false
      t.uuid "role_id", null: false
      t.uuid "tenant_id", null: false
      t.timestamps

      t.index [ "tenant_id", "role_id", "permission_id" ], name: "index_role_permissions_on_tenant_role_permission", unique: true
      t.index [ "tenant_id", "permission_id" ], name: "index_role_permissions_on_tenant_permission"
    end

    # 13. Sessions Table
    create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "device_name"
      t.datetime "expires_at"
      t.string "ip_address"
      t.datetime "last_seen_at"
      t.string "revocation_reason"
      t.datetime "revoked_at"
      t.uuid "revoked_by_id"
      t.uuid "tenant_id", null: false
      t.string "user_agent"
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "expires_at" ], name: "index_sessions_on_expires_at"
      t.index [ "revoked_by_id" ], name: "index_sessions_on_revoked_by_id"
      t.index [ "tenant_id", "expires_at" ], name: "index_sessions_on_tenant_expires"
      t.index [ "tenant_id", "user_id", "revoked_at" ], name: "index_sessions_on_tenant_user_revoked"
      t.index [ "user_id", "expires_at" ], name: "index_sessions_on_active_user_sessions", where: "(revoked_at IS NULL)"
      t.index [ "user_id", "revoked_at" ], name: "index_sessions_on_user_id_and_revoked_at"
      t.index [ "user_id" ], name: "index_sessions_on_user_id"
    end

    # 14. SSO Client Configurations Table
    create_table "sso_client_configurations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.boolean "active", default: true, null: false
      t.string "allowed_scopes", default: [ "openid", "profile", "email" ], null: false, array: true
      t.string "client_id", null: false
      t.string "client_name", null: false
      t.string "client_secret_digest", null: false
      t.string "redirect_uris", default: [], null: false, array: true
      t.uuid "tenant_id", null: false
      t.timestamps

      t.index [ "client_id" ], name: "index_sso_client_configurations_on_client_id", unique: true
      t.index [ "tenant_id" ], name: "index_sso_client_configurations_on_tenant_id"
    end

    # 15. Trusted Devices Table
    create_table "trusted_devices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "device_fingerprint_digest", null: false
      t.string "ip_address"
      t.datetime "last_verified_at", null: false
      t.string "revocation_reason"
      t.datetime "revoked_at"
      t.uuid "revoked_by_id"
      t.uuid "tenant_id", null: false
      t.string "user_agent"
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "device_fingerprint_digest" ], name: "index_trusted_devices_on_device_fingerprint_digest"
      t.index [ "revoked_by_id" ], name: "index_trusted_devices_on_revoked_by_id"
      t.index [ "tenant_id", "user_id", "device_fingerprint_digest" ], name: "index_trusted_devices_active_unique_per_tenant_user", unique: true, where: "(revoked_at IS NULL)"
      t.index [ "tenant_id" ], name: "index_trusted_devices_on_tenant_id"
      t.index [ "user_id" ], name: "index_trusted_devices_on_user_id"
    end

    # 16. User Consents Table
    create_table "user_consents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "consent_signature", null: false
      t.jsonb "consented_scopes", default: {}, null: false
      t.datetime "granted_at", null: false
      t.string "revocation_reason"
      t.datetime "revoked_at"
      t.uuid "revoked_by_id"
      t.uuid "sso_client_configuration_id", null: false
      t.uuid "tenant_id", null: false
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "revoked_by_id" ], name: "index_user_consents_on_revoked_by_id"
      t.index [ "tenant_id", "created_at" ], name: "index_user_consents_on_tenant_and_created"
      t.index [ "user_id", "tenant_id", "sso_client_configuration_id" ], name: "index_active_user_consents_unique", unique: true, where: "(revoked_at IS NULL)"
      t.index [ "user_id", "tenant_id" ], name: "index_user_consents_on_user_id_and_tenant_id"
      t.index [ "user_id" ], name: "index_user_consents_on_user_id"
    end

    # 17. User Passkeys Table
    create_table "user_passkeys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "external_id", null: false
      t.string "nickname"
      t.string "public_key", null: false
      t.integer "sign_count", default: 0, null: false
      t.uuid "tenant_id", null: false
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "external_id" ], name: "index_user_passkeys_on_external_id", unique: true
      t.index [ "tenant_id", "user_id" ], name: "index_user_passkeys_on_tenant_and_user"
      t.index [ "user_id" ], name: "index_user_passkeys_on_user_id"
    end

    # 18. User Permissions Table
    create_table "user_permissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "action", null: false
      t.jsonb "conditions", default: {}, null: false
      t.boolean "is_override", default: true
      t.uuid "permission_id", null: false
      t.string "resource_type", null: false
      t.uuid "tenant_id", null: false
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "tenant_id", "resource_type" ], name: "index_user_permissions_on_tenant_and_resource"
      t.index [ "user_id" ], name: "index_user_permissions_on_user_id"
      t.index [ "tenant_id", "user_id", "permission_id" ], name: "index_user_permissions_on_tenant_user_permission", unique: true
      t.index [ "permission_id" ], name: "index_user_permissions_on_permission_id"
    end

    # 19. User Roles Table
    create_table "user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "role_id", null: false
      t.uuid "tenant_id", null: false
      t.uuid "user_id", null: false
      t.timestamps

      t.index [ "tenant_id", "user_id", "role_id" ], name: "index_user_roles_on_tenant_user_role", unique: true
      t.index [ "tenant_id", "role_id" ], name: "index_user_roles_on_tenant_role"
    end

    # 20. Webhook Endpoints Table
    create_table "webhook_endpoints", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.boolean "active", default: true, null: false
      t.string "events", default: [], null: false, array: true
      t.string "secret", null: false
      t.uuid "tenant_id", null: false
      t.string "url", null: false
      t.timestamps

      t.index [ "tenant_id" ], name: "index_webhook_endpoints_on_tenant_id"
      t.index [ "tenant_id", "url" ], name: "index_webhook_endpoints_on_tenant_url", unique: true
    end

    # 21. Webhook Deliveries Table
    create_table "webhook_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.integer "duration_ms"
      t.string "error_message"
      t.string "event_name", null: false
      t.jsonb "payload", default: {}, null: false
      t.text "response_body"
      t.integer "response_code"
      t.string "status", default: "pending", null: false
      t.uuid "tenant_id", null: false
      t.uuid "webhook_endpoint_id", null: false
      t.integer "attempt_count", default: 0, null: false
      t.datetime "next_retry_at"
      t.datetime "delivered_at"
      t.timestamps

      t.index [ "tenant_id" ], name: "index_webhook_deliveries_on_tenant_id"
      t.index [ "webhook_endpoint_id" ], name: "index_webhook_deliveries_on_webhook_endpoint_id"
      t.index [ "tenant_id", "status", "created_at" ], name: "index_webhook_deliveries_on_tenant_status_created"
      t.index [ "webhook_endpoint_id", "status", "created_at" ], name: "index_webhook_deliveries_on_endpoint_status_created"
      t.index [ "status", "next_retry_at" ], name: "index_webhook_deliveries_on_status_next_retry"
    end

    # 33. Foreign Keys
    add_foreign_key "users", "tenants"
    add_foreign_key "api_clients", "tenants", on_delete: :cascade
    add_foreign_key "api_clients", "users", column: "revoked_by_id", on_delete: :nullify
    add_foreign_key "audit_logs", "tenants"
    add_foreign_key "audit_logs", "users", on_delete: :nullify
    add_foreign_key "email_verification_tokens", "tenants", on_delete: :cascade
    add_foreign_key "email_verification_tokens", "users", on_delete: :cascade
    add_foreign_key "login_attempts", "tenants"
    add_foreign_key "login_attempts", "users", on_delete: :nullify
    add_foreign_key "mfa_backup_codes", "tenants", on_delete: :cascade
    add_foreign_key "mfa_backup_codes", "users", on_delete: :cascade
    add_foreign_key "password_histories", "tenants", on_delete: :cascade
    add_foreign_key "password_histories", "users", on_delete: :cascade
    add_foreign_key "password_reset_tokens", "tenants", on_delete: :cascade
    add_foreign_key "password_reset_tokens", "users", on_delete: :cascade
    add_foreign_key "roles", "tenants", on_delete: :cascade
    add_foreign_key "role_permissions", "permissions", on_delete: :cascade
    add_foreign_key "role_permissions", "roles", on_delete: :cascade
    add_foreign_key "role_permissions", "tenants", on_delete: :cascade
    add_foreign_key "sessions", "tenants", on_delete: :cascade
    add_foreign_key "sessions", "users", column: "revoked_by_id", on_delete: :nullify
    add_foreign_key "sessions", "users", on_delete: :cascade
    add_foreign_key "sso_client_configurations", "tenants", on_delete: :cascade
    add_foreign_key "trusted_devices", "tenants", on_delete: :cascade
    add_foreign_key "trusted_devices", "users", column: "revoked_by_id", on_delete: :nullify
    add_foreign_key "trusted_devices", "users", on_delete: :cascade
    add_foreign_key "user_consents", "sso_client_configurations", on_delete: :cascade
    add_foreign_key "user_consents", "tenants", on_delete: :cascade
    add_foreign_key "user_consents", "users", column: "revoked_by_id", on_delete: :nullify
    add_foreign_key "user_consents", "users", on_delete: :cascade
    add_foreign_key "user_passkeys", "tenants", on_delete: :cascade
    add_foreign_key "user_passkeys", "users", on_delete: :cascade
    add_foreign_key "user_permissions", "permissions", on_delete: :cascade
    add_foreign_key "user_permissions", "tenants", on_delete: :cascade
    add_foreign_key "user_permissions", "users", on_delete: :cascade
    add_foreign_key "user_roles", "roles", on_delete: :cascade
    add_foreign_key "user_roles", "users", on_delete: :cascade
    add_foreign_key "user_roles", "tenants", on_delete: :cascade
    add_foreign_key "webhook_deliveries", "tenants", on_delete: :cascade
    add_foreign_key "webhook_deliveries", "webhook_endpoints", on_delete: :cascade
    add_foreign_key "webhook_endpoints", "tenants", on_delete: :cascade
  end
end
