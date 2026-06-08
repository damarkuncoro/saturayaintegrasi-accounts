# Spesifikasi Keamanan (SECURITY)

Dokumen ini menjelaskan kebijakan, kontrol, dan mekanisme keamanan yang diterapkan pada layanan Accounts, termasuk mekanisme rotasi refresh token serta security checklist wajib.

---

## 1. Rotasi Token & Refresh Token (Token Rotation)

Penggunaan JSON Web Token (JWT) untuk autentikasi API membagi token menjadi dua kategori:
- **`access_token`**: Berdurasi pendek (misal: 15 menit), digunakan untuk mengakses resource API secara langsung.
- **`refresh_token`**: Berdurasi panjang (misal: 7 s.d. 30 hari), disimpan dengan aman di client dan digunakan untuk meminta `access_token` baru tanpa meminta pengguna login ulang.

### Skema Tabel `jwt_refresh_tokens`
Refresh token harus disimpan di database Accounts dalam bentuk digest (hash) untuk mencegah penyalahgunaan apabila database bocor, serta untuk mendukung pembatalan token (revocation).

| Field | Tipe Data | Nullable | Deskripsi |
| --- | --- | --- | --- |
| `id` | UUID | No | Primary key. |
| `tenant_id` | UUID | No | Konteks tenant pemilik token. |
| `user_id` | UUID | No | ID User pemilik token. |
| `token_digest` | String | No | SHA256 hash dari refresh token. |
| `family_id` | UUID | No | ID keluarga token untuk pelacakan rotasi (Token Rotation Family). |
| `expires_at` | DateTime | No | Tanggal kadaluarsa token. |
| `revoked_at` | DateTime | Yes | Waktu token dicabut secara manual (jika ada). |
| `replaced_by_id` | UUID | Yes | Referensi ke token pengganti (relasi rekursif ke `jwt_refresh_tokens.id`). |
| `ip_address` | String | Yes | IP Address pengaju token. |
| `user_agent` | String | Yes | User Agent aplikasi pengaju token. |

### Mekanisme Deteksi Penyalahgunaan (Refresh Token Rotation - RTR)
Untuk mencegah serangan pencurian refresh token, Accounts mengimplementasikan mekanisme **Refresh Token Rotation (RTR)**:

1. Setiap kali `refresh_token` ditukar dengan `access_token` baru, `refresh_token` lama ditandai sebagai `revoked` (atau diisi kolom `replaced_by_id`), dan `refresh_token` baru diterbitkan dalam **Family ID** yang sama.
2. Jika server menerima request tukar token menggunakan `refresh_token` yang **sudah pernah digunakan sebelumnya (invalid/revoked)**, ini merupakan indikasi terjadinya kebocoran token.
3. **Tindakan Keamanan**: Server secara otomatis membatalkan/mencabut (revoke) **seluruh keluarga token** (`family_id` yang sama). Pengguna asli dan penyerang akan dideautentikasi secara paksa dan harus melakukan login ulang.

---

## 2. Security Checklist Layanan Accounts

Sebagai pusat manajemen identitas, Accounts wajib mematuhi standar keamanan berikut:

### Kontrol Kredensial & Autentikasi
- [ ] **Kekuatan Password**: Password minimal 12 karakter, mengandung kombinasi huruf besar, huruf kecil, angka, dan karakter spesial.
- [ ] **Password History**: Mencegah penggunaan ulang password yang sama (menyimpan history hash password sebelumnya).
- [ ] **Credential Digest**: Semua password disimpan menggunakan algoritma hashing yang aman (BCrypt dengan cost factor minimal 12).
- [ ] **Pencabutan Session (Session Revocation)**: Pengguna memiliki kemampuan untuk melihat daftar session aktif dan mencabut session dari perangkat tertentu.

### Multi-Factor Authentication (MFA)
- [ ] **MFA 2FA**: Mendukung verifikasi dua langkah menggunakan Time-based One-time Password (TOTP) seperti Google Authenticator.
- [ ] **Backup Codes**: Menyediakan kode cadangan (backup/recovery codes) yang disimpan dalam bentuk digest (hanya bisa dibaca sekali saat digenerate).

### Pertahanan Terhadap Serangan & Rate Limiting
- [ ] **Login Attempt Limiter**: Akun terkunci otomatis (`locked`) setelah 5 kali gagal login berturut-turut untuk menahan serangan brute-force.
- [ ] **Rate Limit API**: Menggunakan library seperti `Rack::Attack` untuk membatasi request pada endpoint sensitif (login, reset password, register).
- [ ] **CORS Policy**: CORS policy dikonfigurasi ketat hanya memperbolehkan domain resmi yang terdaftar di `BrandConfig.cors_allowed_origins`.
- [ ] **Redirect Safe Guard**: Validasi parameter redirect `return_to` agar tidak mengizinkan redirect ke domain penyerang (Open Redirect Vulnerability). Wajib menggunakan filter berbasis allowlist.

### Keamanan Data & Audit
- [ ] **Audit Logging**: Mencatat setiap perubahan sensitif (ganti password, perubahan email, aktivasi/deaktivasi 2FA, perubahan peran) ke dalam audit trail yang tidak dapat diubah (immutable).
- [ ] **Rotasi Secret**: Mendukung rotasi berkala untuk `SECRET_KEY_BASE` dan JWT signing key tanpa mengganggu session pengguna (melalui key rotation fallback).
- [ ] **HMAC Integration**: Komunikasi sinkronisasi user internal diamankan dengan enkripsi HMAC SHA256.

---

## Dokumen Terkait
- [Architecture Overview](ARCHITECTURE.md)
- [API Contracts](API-CONTRACT.md)
- [Event Contracts](EVENT-CONTRACT.md)
- [Implementation Roadmap](ROADMAP.md)
