# Spesifikasi Keamanan (SECURITY)

Dokumen ini menjelaskan kebijakan, kontrol, dan mekanisme keamanan yang diterapkan pada layanan Accounts, termasuk mekanisme rotasi refresh token serta security checklist wajib.

---

## 1. Rotasi Token & Refresh Token (Token Rotation)

> [!NOTE]
> Fitur database-backed Refresh Token Rotation (RTR) (menggunakan tabel `jwt_refresh_tokens`) telah **diimplementasikan secara penuh** pada Fase 4.
>
> Otentikasi user session yang berjalan di ekosistem Satu Raya dilindungi menggunakan **Wildcard Signed Session Cookies** terenkripsi, pelacakan sesi aktif (active session tracking), perangkat tepercaya (trusted device fingerprinting), audit logging yang ketat, dan **Refresh Token Rotation (RTR)** untuk klien OIDC/OAuth2.

### Skema Tabel `jwt_refresh_tokens`
Refresh token akan disimpan di database Accounts dalam bentuk digest (hash) untuk mencegah penyalahgunaan apabila database bocor, serta untuk mendukung pembatalan token (revocation).

| Field | Tipe Data | Nullable | Deskripsi |
| --- | --- | --- | --- |
| `id` | UUID | No | Primary key. |
| `tenant_id` | UUID | No | Konteks tenant pemilik token. |
| `user_id` | UUID | No | ID User pemilik token. |
| `token_digest` | String | No | SHA256 hash dari refresh token. |
| `family_id` | UUID | No | ID keluarga token untuk pelacakan rotasi (Token Rotation Family). |
| `scopes` | Array[String] | No | Scope yang diberikan kepada token (misal: `["openid", "profile"]`). |
| `expires_at` | DateTime | No | Tanggal kadaluarsa token. |
| `revoked_at` | DateTime | Yes | Waktu token dicabut secara manual (jika ada). |
| `replaced_by_id` | UUID | Yes | Referensi ke token pengganti (relasi rekursif ke `jwt_refresh_tokens.id`). |
| `ip_address` | String | Yes | IP Address pengaju token. |
| `user_agent` | String | Yes | User Agent aplikasi pengaju token. |
| `revocation_reason` | String | Yes | Alasan pembatalan token (e.g. `refreshed`, `revoked`, `replay_attack`, `family_compromised`). |
| `reused_detected_at` | DateTime | Yes | Waktu deteksi penyalahgunaan reuse/replay attack token ini. |
| `reused_from_ip` | String | Yes | IP Address asal request reuse/replay attack. |
| `reused_user_agent` | String | Yes | User Agent asal request reuse/replay attack. |


### Mekanisme Deteksi Penyalahgunaan (Refresh Token Rotation - RTR)
Untuk mencegah serangan pencurian refresh token, Accounts mengimplementasikan mekanisme **Refresh Token Rotation (RTR)**:

1. Setiap kali `refresh_token` ditukar dengan `access_token` baru, `refresh_token` lama ditandai sebagai `revoked` (atau diisi kolom `replaced_by_id`), dan `refresh_token` baru diterbitkan dalam **Family ID** yang sama.
2. Jika server menerima request tukar token menggunakan `refresh_token` yang **sudah pernah digunakan sebelumnya (invalid/revoked)**, ini merupakan indikasi terjadinya kebocoran token.
3. **Tindakan Keamanan**: Server secara otomatis membatalkan/mencabut (revoke) **seluruh keluarga token** (`family_id` yang sama). Pengguna asli dan penyerang akan dideautentikasi secara paksa dan harus melakukan login ulang.

---

## 2. Security Checklist Layanan Accounts

Sebagai pusat manajemen identitas, Accounts wajib mematuhi standar keamanan berikut:

### Kontrol Kredensial & Autentikasi
- [x] **Kekuatan Password**: Password minimal 12 karakter, wajib divalidasi saat registrasi atau perubahan password.
- [x] **Password History**: Mencegah penggunaan ulang password yang sama (menyimpan history hash password sebelumnya di tabel `password_histories`).
- [x] **Credential Digest**: Semua password disimpan menggunakan algoritma hashing BCrypt dengan standard cost factor 12 (`has_secure_password`).
- [x] **Pencabutan Session (Session Revocation)**: Pengguna memiliki kemampuan untuk melihat daftar session aktif dan mencabut (revoke) session tertentu dari dashboard perangkat.

### Multi-Factor Authentication (MFA)
- [x] **MFA 2FA**: Mendukung verifikasi dua langkah menggunakan Time-based One-time Password (TOTP) via library `rotp`.
- [x] **Backup Codes**: Menyediakan kode cadangan (backup/recovery codes) sekali pakai yang disimpan dalam bentuk digest (`mfa_backup_codes`).

### Pertahanan Terhadap Serangan & Rate Limiting
- [x] **Login Attempt Limiter**: Akun terkunci otomatis (`locked_at`) setelah 5 kali gagal login berturut-turut untuk menahan serangan brute-force.
- [x] **Rate Limit API**: Menggunakan `Rack::Attack` middleware untuk membatasi request pada endpoint sensitif:
  - Login by IP: maks 60 request/menit.
  - Login by Email: maks 10 attempt/menit.
  - Registrasi by IP: maks 10 request/menit.
  - Reset Password by IP: maks 10 request/menit.
  - Reset Password by Email: maks 5 request/menit.
  - API General by IP: maks 1000 request/menit.
- [x] **CORS Policy**: CORS policy dikonfigurasi ketat hanya memperbolehkan domain resmi yang dibaca secara dinamis dari `SatuRayaIdentityClient::Identity::BrandConfig.app_domain`.
- [x] **Redirect Safe Guard**: Validasi parameter redirect `return_to` agar tidak mengizinkan redirect ke domain penyerang (Open Redirect Vulnerability). Wajib menggunakan allowlist dinamis yang dibaca dari `SatuRayaIdentityClient::Identity::BrandConfig.allowed_redirect_hosts`.

### Keamanan Data & Audit
- [x] **Audit Logging**: Setiap perubahan sensitif (ganti password, perubahan email, aktivasi/deaktivasi 2FA, perubahan peran) dicatat ke dalam audit trail.
  - **Cryptographic Hash Chain**: Audit logging menggunakan rantai hash (seperti blockchain) di mana setiap entri log menyimpan `previous_hash` dari entri log sebelumnya dan menghitung signature SHA256 miliknya sendiri. Ini menjamin data log tidak dapat diubah (immutable/tamper-proof).
  - **Integrity Verification**: Rantai hash divalidasi secara terjadwal/berkala menggunakan task `bin/rails system:audit:verify`.
- [x] **Rotasi Secret**: Mendukung rotasi berkala untuk `SECRET_KEY_BASE` dan JWT signing key tanpa mengganggu session pengguna (melalui key rotation fallback).
- [x] **HMAC Integration**: Komunikasi sinkronisasi user internal diamankan dengan enkripsi HMAC SHA256.

---

## Dokumen Terkait
- [Architecture Overview](ARCHITECTURE.md)
- [API Contracts](API-CONTRACT.md)
- [Event Contracts](EVENT-CONTRACT.md)
- [Implementation Roadmap](ROADMAP.md)
