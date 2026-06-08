# Kontrak API & Integrasi Data (API-CONTRACT)

Dokumen ini menjelaskan spesifikasi teknis untuk pertukaran data antar service, skema database client internal, serta spesifikasi token introspection endpoint.

---

## 1. Boundary Contract (Kontrak Data Pengguna)

Untuk menghindari dependensi langsung service lain (seperti Jobs, Payroll, Attendance, Contract) ke tabel `users` milik Accounts, didefinisikan kontrak data pengguna standar. Service lain hanya diperbolehkan mengonsumsi payload profil minimal ini.

### JSON Payload Scheme (User Profile)
```json
{
  "user_id": "9f1b98b6-98df-45a8-92c9-12f86db3065b",
  "tenant_id": "c62db73b-b27b-4db4-bfa2-35db4db8b8cb",
  "email": "pekerja@satu-raya.dev",
  "role": "worker",
  "permissions": [
    "jobs.apply",
    "contracts.read"
  ],
  "verified": true,
  "active": true
}
```

### Penjelasan Field:
| Field | Tipe Data | Deskripsi |
| --- | --- | --- |
| `user_id` | UUID | Identifier unik global untuk pengguna. |
| `tenant_id` | UUID | Identifier tenant tempat pengguna bernaung. |
| `email` | String | Alamat email terverifikasi pengguna. |
| `role` | String | Peran global pengguna (misal: `worker`, `employer`, `tenant_admin`, `super_admin`). |
| `permissions` | Array[String] | Hak akses granular yang diberikan kepada pengguna. |
| `verified` | Boolean | Status verifikasi email pengguna. |
| `active` | Boolean | Menandakan apakah akun sedang aktif secara fungsional. |

---

## 2. Skema Database `service_clients`

`service_clients` digunakan khusus untuk autentikasi dan otorisasi komunikasi internal antar service milik monorepo Satu Raya (M2M / Machine-to-Machine). Ini terpisah dari `api_clients` yang ditujukan untuk integrasi pihak ketiga eksternal.

### Struktur Tabel `service_clients`
Tabel ini disimpan pada database Accounts.

| Field | Tipe Data | Nullable | Deskripsi |
| --- | --- | --- | --- |
| `id` | UUID | No | Primary key. |
| `tenant_id` | UUID | Yes | Terikat pada tenant tertentu (jika null, klien bersifat global/system-wide). |
| `service_name` | String | No | Nama microservice internal (misal: `jobs-service`, `payroll-service`). |
| `client_id` | String | No | Unique client identifier (digunakan saat request token). |
| `secret_digest` | String | No | BCrypt digest dari client secret (tidak disimpan plain text). |
| `allowed_scopes` | Array[String] | No | Daftar scope API internal yang diizinkan (misal: `["introspect", "user.sync"]`). |
| `allowed_ips` | Array[String] | No | IP Whitelist untuk membatasi request hanya dari cluster internal. |
| `active` | Boolean | No | Status aktif/non-aktif service client. |
| `rotated_at` | DateTime | Yes | Waktu terakhir kali client secret dirotasi. |

---

## 3. Token Introspection Endpoint

Service internal membutuhkan mekanisme terpusat untuk memvalidasi access token (JWT atau opaque token) tanpa perlu mengimplementasikan logika dekripsi dan validasi local yang berisiko tidak sinkron. Accounts menyediakan endpoint introspection internal.

### HTTP Request
- **Endpoint**: `/oauth/introspect` atau `/api/internal/auth/introspect`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/x-www-form-urlencoded`
  - `Authorization: Basic <base64(client_id:client_secret)>` (Kredensial dari `service_clients`)

### Request Body
| Parameter | Tipe | Wajib | Deskripsi |
| --- | --- | --- | --- |
| `token` | String | Ya | Access token yang akan divalidasi. |
| `token_type_hint` | String | Tidak | Hint jenis token, misal: `access_token`. |

**Contoh Request Curl:**
```bash
curl -X POST https://accounts.satu-raya.dev/api/internal/auth/introspect \
  -H "Authorization: Basic am9icy1zZXJ2aWNlOnNlY3JldC1rZXk=" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=jwt.access.token.here"
```

### HTTP Response (Token Valid & Aktif)
- **Status Code**: `200 OK`
- **Content-Type**: `application/json`

```json
{
  "active": true,
  "user_id": "9f1b98b6-98df-45a8-92c9-12f86db3065b",
  "tenant_id": "c62db73b-b27b-4db4-bfa2-35db4db8b8cb",
  "role": "employer",
  "permissions": [
    "jobs.create",
    "contracts.read"
  ],
  "expires_at": "2026-06-08T12:00:00Z"
}
```

### HTTP Response (Token Kadaluarsa / Tidak Valid)
- **Status Code**: `200 OK`
- **Content-Type**: `application/json`

```json
{
  "active": false
}
```

---

## Dokumen Terkait
- [Architecture Overview](ARCHITECTURE.md)
- [Event Contracts](EVENT-CONTRACT.md)
- [Security Specifications](SECURITY.md)
- [Implementation Roadmap](ROADMAP.md)
