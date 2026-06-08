class AccountsSchemaBaseline < ActiveRecord::Migration[8.1]
  def up
    # Enable extensions
    enable_extension "pg_catalog.plpgsql"
    enable_extension "pgcrypto"

    create_tenants
    create_users
    create_sessions
    create_api_clients
    create_audit_logs
    create_sso_client_configurations
    create_trusted_devices
    create_user_consents
    create_user_passkeys
    create_user_permissions
    create_email_verification_tokens
    create_password_reset_tokens
    create_mfa_backup_codes
    create_password_histories
    create_login_attempts
    create_solid_queue_tables

    add_accounts_foreign_keys
  end

  def down
    # Solid Queue Tables
    drop_table :solid_queue_semaphores, if_exists: true
    drop_table :solid_queue_scheduled_executions, if_exists: true
    drop_table :solid_queue_recurring_tasks, if_exists: true
    drop_table :solid_queue_recurring_executions, if_exists: true
    drop_table :solid_queue_ready_executions, if_exists: true
    drop_table :solid_queue_processes, if_exists: true
    drop_table :solid_queue_pauses, if_exists: true
    drop_table :solid_queue_failed_executions, if_exists: true
    drop_table :solid_queue_claimed_executions, if_exists: true
    drop_table :solid_queue_blocked_executions, if_exists: true
    drop_table :solid_queue_jobs, if_exists: true

    # Accounts Tables
    drop_table :login_attempts, if_exists: true
    drop_table :password_histories, if_exists: true
    drop_table :mfa_backup_codes, if_exists: true
    drop_table :password_reset_tokens, if_exists: true
    drop_table :email_verification_tokens, if_exists: true
    drop_table :user_permissions, if_exists: true
    drop_table :user_passkeys, if_exists: true
    drop_table :user_consents, if_exists: true
    drop_table :trusted_devices, if_exists: true
    drop_table :sso_client_configurations, if_exists: true
    drop_table :audit_logs, if_exists: true
    drop_table :api_clients, if_exists: true
    drop_table :sessions, if_exists: true
    drop_table :users, if_exists: true
    drop_table :tenants, if_exists: true
  end

  private

  def uuid_primary_key
    { id: :uuid, default: -> { "gen_random_uuid()" } }
  end

  def create_tenants
    create_table :tenants, **uuid_primary_key do |t|
      t.boolean :active, default: true, null: false
      t.string :domain
      t.string :name, null: false
      t.string :plan, default: "starter", null: false
      t.string :slug, null: false
      t.jsonb :settings, default: {}, null: false
      t.timestamps

      # Functional indexes for case-insensitive uniqueness
      t.index "lower(domain)", unique: true, name: "index_tenants_on_lower_domain", where: "domain IS NOT NULL"
      t.index "lower(slug)", unique: true, name: "index_tenants_on_lower_slug"
    end
  end

  def create_users
    create_table :users, **uuid_primary_key do |t|
      t.boolean :active, default: true, null: false
      t.string :email, null: false
      t.string :unconfirmed_email
      t.string :first_name, default: "", null: false
      t.string :last_name, default: "", null: false
      t.boolean :otp_required_for_login, default: false, null: false
      t.string :otp_secret
      t.string :password_digest, null: false
      t.string :phone, default: "", null: false
      t.string :provider
      t.integer :role, default: 0, null: false
      t.uuid :tenant_id, null: false
      t.string :uid
      t.string :username
      t.boolean :verified, default: false, null: false
      # Security & Tracking
      t.integer :failed_attempts, default: 0, null: false
      t.datetime :locked_at
      t.datetime :last_login_at
      t.string :last_login_ip
      t.timestamps

      t.index [:tenant_id, :active], name: "index_users_on_tenant_id_and_active"
      # Functional index for case-insensitive email per tenant
      t.index "tenant_id, lower(email)", unique: true, name: "index_users_on_tenant_id_and_lower_email"
      # Functional index for case-insensitive unconfirmed_email per tenant
      t.index "tenant_id, lower(unconfirmed_email)", unique: true, name: "index_users_on_tenant_id_and_lower_unconfirmed_email", where: "unconfirmed_email IS NOT NULL"
      t.index [:tenant_id, :role], name: "index_users_on_tenant_id_and_role"
      t.index [:tenant_id, :verified], name: "index_users_on_tenant_id_and_verified"
      t.index "tenant_id, lower(username)", unique: true, name: "index_users_on_tenant_id_and_lower_username", where: "username IS NOT NULL"
      t.index [:tenant_id, :provider, :uid], unique: true, name: "index_users_on_tenant_provider_uid", where: "provider IS NOT NULL AND uid IS NOT NULL"
    end
  end

  def create_sessions
    create_table :sessions, **uuid_primary_key do |t|
      t.string :device_name
      t.datetime :expires_at
      t.string :ip_address
      t.datetime :last_seen_at
      t.string :user_agent
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.datetime :revoked_at
      t.uuid :revoked_by_id
      t.string :revocation_reason
      t.timestamps

      t.index :expires_at, name: "index_sessions_on_expires_at"
      t.index [:user_id, :expires_at], name: "index_sessions_on_active_user_sessions", where: "(revoked_at IS NULL)"
      t.index [:user_id, :revoked_at], name: "index_sessions_on_user_id_and_revoked_at"
      t.index :user_id, name: "index_sessions_on_user_id"
      t.index :revoked_by_id, name: "index_sessions_on_revoked_by_id"
      t.index [:tenant_id, :user_id, :revoked_at], name: "index_sessions_on_tenant_user_revoked"
      t.index [:tenant_id, :expires_at], name: "index_sessions_on_tenant_expires"
    end
  end

  def create_api_clients
    create_table :api_clients, **uuid_primary_key do |t|
      t.boolean :active, default: true, null: false
      t.string :allowed_ips, default: [], array: true
      t.string :api_key, null: false
      t.string :api_secret_digest, null: false
      t.datetime :expires_at
      t.datetime :last_used_at
      t.string :last_used_ip
      t.string :name, null: false
      t.jsonb :permissions, default: {}, null: false
      t.integer :rate_limit_per_minute, default: 60, null: false
      t.uuid :tenant_id, null: false
      t.timestamps

      t.index :api_key, unique: true, name: "index_api_clients_on_api_key"
      t.index :tenant_id, name: "index_api_clients_on_tenant_id"
    end
  end

  def create_audit_logs
    create_table :audit_logs, **uuid_primary_key do |t|
      t.uuid :tenant_id, null: false
      t.uuid :user_id
      t.string :auditable_type
      t.uuid :auditable_id
      t.string :action, null: false
      t.jsonb :audited_changes, default: {}, null: false
      t.string :request_id
      t.string :remote_ip
      t.string :user_agent
      t.jsonb :metadata, default: {}, null: false
      t.timestamps

      t.index [:auditable_type, :auditable_id], name: "index_audit_logs_on_auditable"
      t.index [:tenant_id, :created_at], name: "index_audit_logs_on_tenant_and_created"
      t.index :user_id, name: "index_audit_logs_on_user_id"
      t.index :request_id, name: "index_audit_logs_on_request_id"
    end
  end

  def create_sso_client_configurations
    create_table :sso_client_configurations, **uuid_primary_key do |t|
      t.boolean :active, default: true, null: false
      t.string :allowed_scopes, default: ["openid", "profile", "email"], null: false, array: true
      t.string :client_id, null: false
      t.string :client_name, null: false
      t.string :client_secret_digest, null: false
      t.string :redirect_uris, default: [], null: false, array: true
      t.uuid :tenant_id, null: false
      t.timestamps

      t.index :client_id, unique: true, name: "index_sso_client_configurations_on_client_id"
      t.index :tenant_id, name: "index_sso_client_configurations_on_tenant_id"
    end
  end

  def create_trusted_devices
    create_table :trusted_devices, **uuid_primary_key do |t|
      t.string :device_fingerprint, null: false
      t.string :ip_address
      t.datetime :last_verified_at, null: false
      t.string :user_agent
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.datetime :revoked_at
      t.uuid :revoked_by_id
      t.string :revocation_reason
      t.timestamps

      t.index :device_fingerprint, name: "index_trusted_devices_on_device_fingerprint"
      t.index [:tenant_id, :user_id, :device_fingerprint], unique: true, name: "index_trusted_devices_active_unique_per_tenant_user", where: "revoked_at IS NULL"
      t.index :user_id, name: "index_trusted_devices_on_user_id"
      t.index :revoked_by_id, name: "index_trusted_devices_on_revoked_by_id"
      t.index :tenant_id, name: "index_trusted_devices_on_tenant_id"
    end
  end

  def create_user_consents
    create_table :user_consents, **uuid_primary_key do |t|
      t.string :consent_signature, null: false
      t.jsonb :consented_scopes, default: {}, null: false
      t.datetime :granted_at, null: false
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.uuid :sso_client_configuration_id, null: false
      t.datetime :revoked_at
      t.uuid :revoked_by_id
      t.string :revocation_reason
      t.timestamps

      t.index [:tenant_id, :created_at], name: "index_user_consents_on_tenant_and_created"
      t.index [:user_id, :tenant_id], name: "index_user_consents_on_user_id_and_tenant_id"
      t.index [:user_id, :tenant_id, :sso_client_configuration_id], unique: true, where: "revoked_at IS NULL", name: "index_active_user_consents_unique"
      t.index :user_id, name: "index_user_consents_on_user_id"
      t.index :revoked_by_id, name: "index_user_consents_on_revoked_by_id"
    end
  end

  def create_user_passkeys
    create_table :user_passkeys, **uuid_primary_key do |t|
      t.string :external_id, null: false
      t.string :nickname
      t.string :public_key, null: false
      t.integer :sign_count, default: 0, null: false
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.timestamps

      t.index :external_id, unique: true, name: "index_user_passkeys_on_external_id"
      t.index :user_id, name: "index_user_passkeys_on_user_id"
      t.index [:tenant_id, :user_id], name: "index_user_passkeys_on_tenant_and_user"
    end
  end

  def create_user_permissions
    create_table :user_permissions, **uuid_primary_key do |t|
      t.string :action, null: false
      t.jsonb :conditions, default: {}, null: false
      t.string :resource_type, null: false
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.timestamps

      t.index [:tenant_id, :resource_type], name: "index_user_permissions_on_tenant_and_resource"
      t.index [:user_id, :resource_type, :action], unique: true, name: "index_user_permissions_on_user_resource_action"
      t.index :user_id, name: "index_user_permissions_on_user_id"
    end
  end

  def create_email_verification_tokens
    create_table :email_verification_tokens, **uuid_primary_key do |t|
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.timestamps

      t.index :token_digest, unique: true, name: "index_email_verification_tokens_on_token_digest"
      t.index [:tenant_id, :user_id, :used_at], name: "index_email_verification_tokens_on_tenant_user_used"
      t.index :user_id, name: "index_email_verification_tokens_on_user_id"
    end
  end

  def create_password_reset_tokens
    create_table :password_reset_tokens, **uuid_primary_key do |t|
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.string :request_ip
      t.timestamps

      t.index :token_digest, unique: true, name: "index_password_reset_tokens_on_token_digest"
      t.index [:tenant_id, :user_id, :used_at], name: "index_password_reset_tokens_on_tenant_user_used"
      t.index :user_id, name: "index_password_reset_tokens_on_user_id"
    end
  end

  def create_mfa_backup_codes
    create_table :mfa_backup_codes, **uuid_primary_key do |t|
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.string :code_digest, null: false
      t.datetime :used_at
      t.timestamps

      t.index [:tenant_id, :user_id, :used_at], name: "index_mfa_backup_codes_on_tenant_user_used"
      t.index [:tenant_id, :user_id, :code_digest], unique: true, name: "index_mfa_backup_codes_unique_digest_per_user"
      t.index :user_id, name: "index_mfa_backup_codes_on_user_id"
    end
  end

  def create_password_histories
    create_table :password_histories, **uuid_primary_key do |t|
      t.uuid :tenant_id, null: false
      t.uuid :user_id, null: false
      t.string :password_digest, null: false
      t.timestamps

      t.index [:tenant_id, :user_id, :created_at], name: "index_password_histories_on_tenant_user_created"
      t.index :user_id, name: "index_password_histories_on_user_id"
    end
  end

  def create_login_attempts
    create_table :login_attempts, **uuid_primary_key do |t|
      t.uuid :tenant_id, null: false
      t.uuid :user_id
      t.string :email, null: false
      t.string :ip_address
      t.string :user_agent
      t.boolean :success, default: false, null: false
      t.string :failure_reason
      t.timestamps

      t.index "tenant_id, lower(email), created_at", name: "index_login_attempts_on_tenant_lower_email_created"
      t.index [:ip_address, :created_at], name: "index_login_attempts_on_ip_and_created"
      t.index :user_id, name: "index_login_attempts_on_user_id"
    end
  end

  def create_solid_queue_tables
    create_table :solid_queue_jobs do |t|
      t.string :active_job_id
      t.text :arguments
      t.string :class_name, null: false
      t.string :concurrency_key
      t.datetime :finished_at
      t.integer :priority, default: 0, null: false
      t.string :queue_name, null: false
      t.datetime :scheduled_at
      t.timestamps

      t.index :active_job_id, name: "index_solid_queue_jobs_on_active_job_id"
      t.index :class_name, name: "index_solid_queue_jobs_on_class_name"
      t.index :finished_at, name: "index_solid_queue_jobs_on_finished_at"
      t.index [:queue_name, :finished_at], name: "index_solid_queue_jobs_for_filtering"
      t.index [:scheduled_at, :finished_at], name: "index_solid_queue_jobs_for_alerting"
    end

    create_table :solid_queue_blocked_executions do |t|
      t.string :concurrency_key, null: false
      t.datetime :created_at, null: false
      t.datetime :expires_at, null: false
      t.bigint :job_id, null: false
      t.integer :priority, default: 0, null: false
      t.string :queue_name, null: false

      t.index [:concurrency_key, :priority, :job_id], name: "index_solid_queue_blocked_executions_for_release"
      t.index [:expires_at, :concurrency_key], name: "index_solid_queue_blocked_executions_for_maintenance"
      t.index :job_id, unique: true, name: "index_solid_queue_blocked_executions_on_job_id"
    end

    create_table :solid_queue_claimed_executions do |t|
      t.datetime :created_at, null: false
      t.bigint :job_id, null: false
      t.bigint :process_id

      t.index :job_id, unique: true, name: "index_solid_queue_claimed_executions_on_job_id"
      t.index [:process_id, :job_id], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
    end

    create_table :solid_queue_failed_executions do |t|
      t.datetime :created_at, null: false
      t.text :error
      t.bigint :job_id, null: false

      t.index :job_id, unique: true, name: "index_solid_queue_failed_executions_on_job_id"
    end

    create_table :solid_queue_pauses do |t|
      t.datetime :created_at, null: false
      t.string :queue_name, null: false

      t.index :queue_name, unique: true, name: "index_solid_queue_pauses_on_queue_name"
    end

    create_table :solid_queue_processes do |t|
      t.datetime :created_at, null: false
      t.string :hostname
      t.string :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.text :metadata
      t.string :name, null: false
      t.integer :pid, null: false
      t.bigint :supervisor_id

      t.index :last_heartbeat_at, name: "index_solid_queue_processes_on_last_heartbeat_at"
      t.index [:name, :supervisor_id], unique: true, name: "index_solid_queue_processes_on_name_and_supervisor_id"
      t.index :supervisor_id, name: "index_solid_queue_processes_on_supervisor_id"
    end

    create_table :solid_queue_ready_executions do |t|
      t.datetime :created_at, null: false
      t.bigint :job_id, null: false
      t.integer :priority, default: 0, null: false
      t.string :queue_name, null: false

      t.index :job_id, unique: true, name: "index_solid_queue_ready_executions_on_job_id"
      t.index [:priority, :job_id], name: "index_solid_queue_poll_all"
      t.index [:queue_name, :priority, :job_id], name: "index_solid_queue_poll_by_queue"
    end

    create_table :solid_queue_recurring_executions do |t|
      t.datetime :created_at, null: false
      t.bigint :job_id, null: false
      t.datetime :run_at, null: false
      t.string :task_key, null: false

      t.index :job_id, unique: true, name: "index_solid_queue_recurring_executions_on_job_id"
      t.index [:task_key, :run_at], unique: true, name: "index_solid_queue_recurring_executions_on_task_key_and_run_at"
    end

    create_table :solid_queue_recurring_tasks do |t|
      t.text :arguments
      t.string :class_name
      t.string :command, limit: 2048
      t.text :description
      t.string :key, null: false
      t.integer :priority, default: 0
      t.string :queue_name
      t.string :schedule, null: false
      t.boolean :static, default: true, null: false
      t.timestamps

      t.index :key, unique: true, name: "index_solid_queue_recurring_tasks_on_key"
      t.index :static, name: "index_solid_queue_recurring_tasks_on_static"
    end

    create_table :solid_queue_scheduled_executions do |t|
      t.datetime :created_at, null: false
      t.bigint :job_id, null: false
      t.integer :priority, default: 0, null: false
      t.string :queue_name, null: false
      t.datetime :scheduled_at, null: false

      t.index :job_id, unique: true, name: "index_solid_queue_scheduled_executions_on_job_id"
      t.index [:scheduled_at, :priority, :job_id], name: "index_solid_queue_dispatch_all"
    end

    create_table :solid_queue_semaphores do |t|
      t.datetime :expires_at, null: false
      t.string :key, null: false
      t.integer :value, default: 1, null: false
      t.timestamps

      t.index :expires_at, name: "index_solid_queue_semaphores_on_expires_at"
      t.index [:key, :value], name: "index_solid_queue_semaphores_on_key_and_value"
      t.index :key, unique: true, name: "index_solid_queue_semaphores_on_key"
    end
  end

  def add_accounts_foreign_keys
    add_foreign_key :api_clients, :tenants
    add_foreign_key :audit_logs, :tenants
    add_foreign_key :audit_logs, :users, on_delete: :nullify
    add_foreign_key :sessions, :tenants, on_delete: :cascade
    add_foreign_key :sessions, :users
    add_foreign_key :sessions, :users, column: :revoked_by_id, on_delete: :nullify
    add_foreign_key :solid_queue_blocked_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_claimed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_ready_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :sso_client_configurations, :tenants, on_delete: :cascade
    add_foreign_key :trusted_devices, :tenants, on_delete: :cascade
    add_foreign_key :trusted_devices, :users, on_delete: :cascade
    add_foreign_key :trusted_devices, :users, column: :revoked_by_id, on_delete: :nullify
    add_foreign_key :user_consents, :tenants, on_delete: :cascade
    add_foreign_key :user_consents, :users, on_delete: :cascade
    add_foreign_key :user_consents, :users, column: :revoked_by_id, on_delete: :nullify
    add_foreign_key :user_consents, :sso_client_configurations, on_delete: :cascade
    add_foreign_key :user_passkeys, :tenants, on_delete: :cascade
    add_foreign_key :user_passkeys, :users, on_delete: :cascade
    add_foreign_key :user_permissions, :tenants
    add_foreign_key :user_permissions, :users
    add_foreign_key :login_attempts, :tenants, on_delete: :cascade
    add_foreign_key :login_attempts, :users, on_delete: :nullify
    add_foreign_key :email_verification_tokens, :tenants, on_delete: :cascade
    add_foreign_key :email_verification_tokens, :users, on_delete: :cascade
    add_foreign_key :password_reset_tokens, :tenants, on_delete: :cascade
    add_foreign_key :password_reset_tokens, :users, on_delete: :cascade
    add_foreign_key :mfa_backup_codes, :tenants, on_delete: :cascade
    add_foreign_key :mfa_backup_codes, :users, on_delete: :cascade
    add_foreign_key :password_histories, :tenants, on_delete: :cascade
    add_foreign_key :password_histories, :users, on_delete: :cascade
  end
end
