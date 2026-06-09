Update ini **jauh lebih bagus** dari versi sebelumnya. Banyak catatan utama sudah masuk: FK `users -> tenants`, FK RBAC ke tenant, revocation API client, index audit tambahan, expiry token index, webhook unique URL, dan index delivery status.

Nilai sekarang: **9 / 10**.

Masih ada beberapa hal penting yang saya sarankan diperbaiki sebelum dianggap final production.

---

# 1. Masalah terbesar yang masih tersisa: tenant consistency belum dikunci database

Walaupun sekarang `user_roles` punya:

```ruby
t.index ["tenant_id", "user_id", "role_id"],
  name: "index_user_roles_on_tenant_user_role",
  unique: true
```

FK-nya masih seperti ini:

```ruby
add_foreign_key "user_roles", "roles", on_delete: :cascade
add_foreign_key "user_roles", "users", on_delete: :cascade
add_foreign_key "user_roles", "tenants", on_delete: :cascade
```

Ini **belum mencegah kasus silang tenant**.

Contoh data yang masih bisa lolos:

```text
user_roles.tenant_id = Tenant A
user_roles.user_id   = User dari Tenant B
user_roles.role_id   = Role dari Tenant A
```

Database hanya mengecek bahwa user, role, dan tenant itu ada. Database belum mengecek bahwa semuanya berada dalam tenant yang sama.

Untuk tahap sekarang, ini masih bisa ditutup di model Rails:

```ruby
class UserRole < ApplicationRecord
  belongs_to :tenant
  belongs_to :user
  belongs_to :role

  validate :tenant_must_match_user_and_role

  private

  def tenant_must_match_user_and_role
    return if tenant_id.blank? || user.blank? || role.blank?

    errors.add(:user_id, "must belong to the same tenant") if user.tenant_id != tenant_id
    errors.add(:role_id, "must belong to the same tenant") if role.tenant_id != tenant_id
  end
end
```

Hal yang sama berlaku untuk:

```text
role_permissions
user_permissions
sessions
trusted_devices
user_consents
user_passkeys
password_reset_tokens
email_verification_tokens
mfa_backup_codes
password_histories
```

Rails `add_foreign_key` secara standar bekerja untuk FK kolom tunggal; untuk composite FK/constraint tenant-level yang lebih keras biasanya butuh pendekatan SQL/constraint tambahan. Rails juga menyediakan dukungan PostgreSQL seperti UUID, index, unique constraint, dan deferrable FK, tapi untuk desain multi-kolom yang sangat ketat perlu dirancang lebih hati-hati. ([Ruby on Rails Guides][1])

---

# 2. `on_delete: :cascade` terlalu agresif untuk sistem compliance

Sekarang kamu memakai cascade di banyak tempat:

```ruby
add_foreign_key "users", "tenants", on_delete: :cascade
add_foreign_key "sessions", "users", on_delete: :cascade
add_foreign_key "password_histories", "users", on_delete: :cascade
add_foreign_key "login_attempts", "tenants", on_delete: :cascade
add_foreign_key "api_clients", "tenants", on_delete: :cascade
```

Secara teknis valid. Rails migration memang mendukung `add_foreign_key` dan opsi seperti `on_delete`. ([Ruby on Rails Guides][1])

Tapi secara **audit/legal**, ini berbahaya kalau suatu hari ada hard delete tenant. Data berikut bisa ikut hilang:

```text
users
login_attempts
sessions
password_histories
api_clients
webhook_deliveries
token history
trusted devices
```

Karena kamu sudah punya `deleted_at`, saya sarankan prinsipnya:

```text
Data operasional sementara       boleh cascade
Data audit/security/compliance   jangan cascade
Data identity utama              soft delete, bukan hard delete
```

Saran perubahan untuk production:

```ruby
add_foreign_key "users", "tenants"
add_foreign_key "login_attempts", "tenants"
add_foreign_key "audit_logs", "tenants"
```

Untuk tabel token yang memang temporary, cascade masih masuk akal:

```ruby
email_verification_tokens
password_reset_tokens
mfa_backup_codes
sessions
trusted_devices
```

Namun untuk sistem SatuKerja yang punya kontrak, payroll, legal identity, dan audit, saya lebih suka **jangan pernah hard-delete tenant/user**.

---

# 3. `api_clients` sudah lebih baik, tapi perlu index active/revoked

Sekarang sudah ada:

```ruby
t.datetime "revoked_at"
t.uuid "revoked_by_id"
t.string "revocation_reason"
```

Bagus.

Tapi untuk lookup API key production, biasanya query-nya seperti ini:

```ruby
ApiClient.find_by(api_key: key, active: true, revoked_at: nil)
```

Saat ini hanya ada:

```ruby
t.index ["api_key"], unique: true
t.index ["tenant_id"]
t.index ["revoked_by_id"]
```

Tambahkan index operasional:

```ruby
t.index ["api_key", "active", "revoked_at"],
  name: "index_api_clients_on_key_active_revoked"
```

Atau karena `api_key` sudah unique, index ini tidak wajib. Tapi query dashboard tenant akan lebih butuh:

```ruby
t.index ["tenant_id", "active", "revoked_at"],
  name: "index_api_clients_on_tenant_active_revoked"
```

Tambahkan juga:

```ruby
t.index ["tenant_id", "expires_at"],
  name: "index_api_clients_on_tenant_expires_at"
```

---

# 4. `user_permissions.permission_id` masih nullable tapi cascade

Bagian ini masih agak ambigu:

```ruby
t.uuid "permission_id"
```

Lalu FK:

```ruby
add_foreign_key "user_permissions", "permissions", on_delete: :cascade
```

Kalau `permission_id` boleh kosong, berarti kamu mendukung permission custom berbasis:

```ruby
resource_type + action
```

Tapi kalau permission master dihapus, record user permission yang mengarah ke permission itu akan ikut hilang.

Saya sarankan pilih salah satu.

## Opsi A — permission wajib dari master

Lebih rapi untuk RBAC enterprise:

```ruby
t.uuid "permission_id", null: false
```

Dan unique index-nya diganti menjadi:

```ruby
t.index ["tenant_id", "user_id", "permission_id"],
  name: "index_user_permissions_on_tenant_user_permission",
  unique: true
```

## Opsi B — user permission boleh custom

Biarkan nullable, tapi ubah FK menjadi:

```ruby
add_foreign_key "user_permissions", "permissions", on_delete: :nullify
```

Untuk sistem kamu, saya lebih sarankan **Opsi A**, karena permission sebaiknya dikontrol dari master `permissions`.

---

# 5. `role_permissions.conditions` sebaiknya `null: false`

Sekarang:

```ruby
t.jsonb "conditions", default: {}
```

Sebaiknya:

```ruby
t.jsonb "conditions", default: {}, null: false
```

Agar kode policy tidak perlu menangani `nil`.

---

# 6. `roles.system_defined` sebaiknya `null: false`

Sekarang:

```ruby
t.boolean "system_defined", default: false
```

Sebaiknya:

```ruby
t.boolean "system_defined", default: false, null: false
```

Ini kecil, tapi bagus untuk konsistensi.

---

# 7. `user_roles` perlu index dari sisi role

Sekarang hanya ada:

```ruby
t.index ["tenant_id", "user_id", "role_id"],
  name: "index_user_roles_on_tenant_user_role",
  unique: true
```

Ini bagus untuk cek role user.

Tapi untuk query seperti:

```text
tampilkan semua user dengan role employer
tampilkan semua admin tenant ini
```

Tambahkan:

```ruby
t.index ["tenant_id", "role_id"],
  name: "index_user_roles_on_tenant_role"
```

---

# 8. `role_permissions` perlu index dari sisi permission

Sekarang hanya ada:

```ruby
t.index ["tenant_id", "role_id", "permission_id"],
  name: "index_role_permissions_on_tenant_role_permission",
  unique: true
```

Tambahkan:

```ruby
t.index ["tenant_id", "permission_id"],
  name: "index_role_permissions_on_tenant_permission"
```

Ini berguna saat ingin melihat role mana saja yang punya permission tertentu.

---

# 9. `permissions.slug` global unique sudah benar

Ini bagus:

```ruby
t.index ["slug"], name: "index_permissions_on_slug", unique: true
```

Karena `permissions` adalah master global, bukan tenant-scoped.

Contoh permission:

```text
users.read
users.create
users.update
contracts.sign
payrolls.read
attendance.approve
api_clients.rotate_secret
```

Saya sarankan nanti format `slug` konsisten:

```text
resource.action
```

Contoh:

```text
users.read
users.invite
users.disable
roles.assign
sessions.revoke
audit_logs.read
webhooks.manage
```

---

# 10. `users.role` masih double dengan RBAC

Kamu masih punya:

```ruby
t.integer "role", default: 0, null: false
```

Dan juga punya:

```text
roles
user_roles
permissions
role_permissions
user_permissions
```

Ini tidak salah, tapi harus jelas fungsinya.

Saran saya:

```text
users.role        = role dasar / account type
user_roles        = authorization detail
user_permissions  = override khusus
```

Contoh:

```ruby
enum :role, {
  worker: 0,
  employer: 1,
  admin: 2,
  super_admin: 3
}
```

Jangan pakai `users.role` untuk semua permission detail. Gunakan hanya untuk routing awal atau klasifikasi user.

---

# 11. `users.revoked_at` agak ambigu

Di `users` ada:

```ruby
t.datetime "disabled_at"
t.datetime "revoked_at"
```

Untuk user, istilah yang umum:

```text
disabled_at  = akun dinonaktifkan admin
locked_at    = akun terkunci karena gagal login
deleted_at   = soft delete
revoked_at   = kurang jelas untuk user
```

`revoked_at` lebih cocok untuk:

```text
sessions
trusted_devices
api_clients
user_consents
tokens
```

Untuk user, saya sarankan ganti menjadi salah satu:

```ruby
t.datetime "access_revoked_at"
t.uuid "access_revoked_by_id"
t.string "access_revocation_reason"
```

Atau hapus `revoked_at` dari `users` kalau belum jelas kegunaannya.

---

# 12. Token digest unique global sudah aman

Ini bagus:

```ruby
t.index ["token_digest"], unique: true
```

Untuk `email_verification_tokens` dan `password_reset_tokens`, global unique digest aman dan sederhana.

Tambahan bagus yang sudah kamu lakukan:

```ruby
t.index ["expires_at"]
```

Ini akan membantu cleanup job:

```ruby
ExpiredTokenCleanupJob
```

---

# 13. `trusted_devices.device_fingerprint_digest` index global tidak wajib unique

Kamu punya:

```ruby
t.index ["device_fingerprint_digest"],
  name: "index_trusted_devices_on_device_fingerprint_digest"
```

Dan unique active:

```ruby
t.index ["tenant_id", "user_id", "device_fingerprint_digest"],
  unique: true,
  where: "(revoked_at IS NULL)"
```

Ini bagus. Global index bisa berguna untuk security analytics, misalnya mendeteksi satu device fingerprint dipakai banyak akun.

---

# 14. Webhook sudah jauh lebih matang

Bagian ini sudah bagus:

```ruby
t.index ["tenant_id", "url"], unique: true
t.index ["tenant_id", "status", "created_at"]
t.index ["webhook_endpoint_id", "status", "created_at"]
```

Saran tambahan opsional:

```ruby
t.integer "attempt_count", default: 0, null: false
t.datetime "next_retry_at"
t.datetime "delivered_at"
```

Index:

```ruby
t.index ["status", "next_retry_at"],
  name: "index_webhook_deliveries_on_status_next_retry"
```

Ini penting kalau nanti webhook delivery pakai retry worker.

---

# 15. Solid Queue masih sebaiknya dipisah

Secara teknis boleh, tapi secara arsitektur saya tetap sarankan Solid Queue tidak digabung ke `AccountsSchemaBaseline`.

Lebih bersih:

```text
db/migrate/xxxx_create_accounts_schema.rb
db/queue_schema.rb
```

Atau:

```text
db/migrate/xxxx_create_accounts_schema.rb
db/migrate/xxxx_create_solid_queue_schema.rb
```

Alasannya sederhana: Solid Queue adalah infrastructure schema, bukan domain schema identity. Kalau nanti kamu upgrade Rails/Solid Queue, lebih mudah maintenance kalau dipisah. Solid Queue sendiri memang backend job berbasis database untuk Rails/Active Job, jadi tabel-tabelnya bersifat infrastruktur.

---

# 16. Patch kecil yang saya rekomendasikan

Berikut patch kecil yang menurut saya paling worth it:

```ruby
# roles
t.boolean "system_defined", default: false, null: false

# role_permissions
t.jsonb "conditions", default: {}, null: false
t.index ["tenant_id", "permission_id"], name: "index_role_permissions_on_tenant_permission"

# user_roles
t.index ["tenant_id", "role_id"], name: "index_user_roles_on_tenant_role"

# user_permissions
t.index ["permission_id"], name: "index_user_permissions_on_permission_id"

# api_clients
t.index ["tenant_id", "active", "revoked_at"], name: "index_api_clients_on_tenant_active_revoked"
t.index ["tenant_id", "expires_at"], name: "index_api_clients_on_tenant_expires_at"

# webhook_deliveries, optional
t.integer "attempt_count", default: 0, null: false
t.datetime "next_retry_at"
t.datetime "delivered_at"
t.index ["status", "next_retry_at"], name: "index_webhook_deliveries_on_status_next_retry"
```

---

# 17. Final judgement

Versi ini sudah **layak dijadikan baseline development/staging**.

Untuk production, saya sarankan selesaikan 4 hal ini dulu:

1. Kurangi `on_delete: :cascade` untuk data compliance/audit.
2. Tambahkan validasi tenant consistency di model.
3. Rapikan `user_permissions.permission_id`: wajib master permission atau custom permission.
4. Pisahkan Solid Queue dari baseline domain schema.

Struktur kamu sekarang sudah kuat untuk:

```text
multi-tenant login
email verification
password reset
MFA
passkeys
trusted devices
session revocation
OAuth/SSO client
user consent
RBAC/ABAC
API client auth
audit trail
webhook events
background jobs
```

Jadi arahnya sudah benar. Setelah ini, langkah terbaik adalah masuk ke **Model Layer + Concern Layer**, bukan menambah tabel lagi.

[1]: https://guides.rubyonrails.org/active_record_migrations.html?utm_source=chatgpt.com "Active Record Migrations"
