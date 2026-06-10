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

## 2. Skema Database `api_clients` & `service_clients` (M2M / Machine-to-Machine)

Untuk mendukung komunikasi langsung programatik, database Accounts menyediakan dua tabel untuk Machine-to-Machine (M2M) integration:

1. **`api_clients`**: Digunakan untuk integrasi API publik/eksternal.
2. **`service_clients`**: Digunakan khusus untuk autentikasi antar-service internal Satu Raya (misal: Jobs, Payroll, dll).

### Struktur Tabel `service_clients`
Tabel ini disimpan pada database Accounts dengan skema sebagai berikut:

| Field | Tipe Data | Nullable | Deskripsi |
| --- | --- | --- | --- |
| `id` | UUID | No | Primary key. |
| `tenant_id` | UUID | Yes | Terikat pada tenant tertentu (jika null, klien bersifat global/system-wide). |
| `service_name` | String | No | Nama microservice internal (misal: `jobs-service`, `payroll-service`). |
| `client_id` | String | No | Unique client identifier (berindeks unik global). |
| `secret_digest` | String | No | BCrypt digest dari client secret (tidak disimpan plain text). |
| `allowed_scopes` | Array[String] | No | Daftar scope API internal yang diizinkan (misal: `["introspect", "user.sync"]`). |
| `allowed_ips` | Array[String] | No | IP Whitelist untuk membatasi request hanya dari cluster internal. |
| `active` | Boolean | No | Status aktif/non-aktif service client (default: true). |
| `rotated_at` | DateTime | Yes | Waktu terakhir kali client secret dirotasi. |

---

## 3. Token Introspection Endpoint

Service internal menggunakan Token Introspection Endpoint untuk memvalidasi access token (JWT) secara terpusat. Endpoint ini memvalidasi token, memastikan user dan tenant aktif, serta mengembalikan metadata otorisasi/role/permissions.

### HTTP Request
- **Endpoint**: `/oauth/introspect`
- **Method**: `POST`
- **Headers**:
  - `Content-Type: application/x-www-form-urlencoded` atau `application/json`
  - `Authorization: Basic <base64(client_id:client_secret)>` (Menggunakan kredensial dari `service_clients`)

### Request Body
| Parameter | Tipe | Wajib | Deskripsi |
| --- | --- | --- | --- |
| `token` | String | Ya | Access token (JWT) yang akan divalidasi. |

**Contoh Request Curl:**
```bash
curl -X POST https://accounts.satu-raya.dev/oauth/introspect \
  -H "Authorization: Basic dGVzdF9zZXJ2aWNlX2NsaWVudF9pZDpzdXBlcl9zZWN1cmVfc2VydmljZV9zZWNyZXRfMTIz" \
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
  "role": "worker",
  "permissions": [
    "jobs.apply",
    "contracts.read"
  ],
  "expires_at": "2026-06-08T12:00:00Z"
}
```

### HTTP Response (Token Kadaluarsa / Tidak Valid / Tenant Nonaktif)
- **Status Code**: `200 OK`
- **Content-Type**: `application/json`

```json
{
  "active": false
}
```

### HTTP Response (Kredensial Client Salah / Tidak Aktif)
- **Status Code**: `401 Unauthorized`
- **Content-Type**: `application/json`

```json
{
  "error": "invalid_client"
}
```

---

## Dokumen Terkait
- [Architecture Overview](ARCHITECTURE.md)
- [Event Contracts](EVENT-CONTRACT.md)
- [Security Specifications](SECURITY.md)
- [Implementation Roadmap](ROADMAP.md)
