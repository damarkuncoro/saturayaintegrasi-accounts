# Fitur & Panduan Penggunaan Satu Raya Accounts

Dokumen ini menjelaskan daftar fitur utama yang tersedia di layanan **Satu Raya Accounts (IAM)** dan bagaimana cara menggunakannya baik sebagai pengembang maupun sebagai penyewa (tenant).

---

## 1. Multi-tenant Branding (Kustomisasi Identitas)

Aplikasi ini dirancang untuk dapat digunakan kembali (*reusable*) oleh berbagai brand dengan satu basis kode yang sama.

### Fitur Utama:
- Kustomisasi Nama Brand, Logo, dan Warna Primer.
- Resolusi Tenant otomatis berdasarkan domain/subdomain (misal: `accounts.satukerja.dev`).
- Variasi Layout (Centered, Split, Compact) yang dapat dikonfigurasi.

### Cara Menggunakan:
1. **Tambah Tenant**: Buat data tenant baru di database melalui Rails console:
   ```ruby
   System::Tenant.create!(slug: 'nama-brand', domain: 'brand.dev', name: 'Nama Brand')
   ```
2. **Konfigurasi Env**: Setel variabel lingkungan di Docker/Server:
   - `BRAND_NAME`: "Nama Brand Anda"
   - `BRAND_PRIMARY_COLOR`: "#hexcolor"
   - `BRAND_LOGO_URL`: "https://link-ke-logo.png"
3. **Caddy/Proxy**: Tambahkan domain baru ke [Caddyfile](../../infra/compose/Caddyfile) dan jalankan skrip `trust-ssl.sh`.

---

## 2. Autentikasi & Keamanan Lanjut

Menyediakan standar keamanan industri untuk melindungi akun pengguna.

### Fitur Utama:
- **Two-Factor Authentication (2FA)**: Mendukung TOTP (Google Authenticator, dll) dan Kode Cadangan Darurat.
- **Trusted Devices**: Mengurangi frekuensi tantangan 2FA pada perangkat yang dikenal.
- **Session Management**: Pengguna dapat melihat dan mencabut sesi aktif dari perangkat lain.
- **Password History**: Mencegah penggunaan kembali kata sandi lama.

### Cara Menggunakan:
- Pengguna dapat mengaktifkan 2FA melalui menu **Keamanan** di halaman `/two_factor_settings`.
- Pengembang dapat mewajibkan 2FA untuk peran tertentu melalui kebijakan Pundit.

---

## 3. Single Sign-On (SSO) Integration

Memungkinkan aplikasi lain dalam ekosistem (seperti Portal Kerja atau Bisnis) menggunakan sesi login dari Accounts.

### Fitur Utama:
- **Wildcard Signed Cookies**: Sesi login berlaku untuk seluruh subdomain (misal: `*.satukerja.dev`).
- **Identity Client SDK**: Package `packages/identity-client` untuk integrasi cepat ke aplikasi Rails lain.

### Cara Menggunakan:
1. Tambahkan gem `satu-raya-identity-client` ke aplikasi tujuan.
2. Gunakan concern `SatuRayaIdentityClient::Authentication` di controller:
   ```ruby
   class ApplicationController < ActionController::Base
     include SatuRayaIdentityClient::Authentication
   end
   ```

---

## 4. Audit Log Integrity (Keamanan Data)

Setiap perubahan penting pada akun (ganti password, ganti email, login) dicatat dengan jaminan integritas.

### Fitur Utama:
- **Cryptographic Hash Chain**: Setiap log terkait dengan hash log sebelumnya, sehingga tidak dapat dimanipulasi tanpa merusak rantai hash.
- **Metadata Lengkap**: Mencatat IP Address, User Agent, dan Request ID untuk setiap aksi.

### Cara Menggunakan:
- Verifikasi integritas log secara berkala melalui perintah terminal:
  ```bash
  bin/rails system:audit:verify
  ```

---

## 5. Webhooks & Event Bus

Sinkronisasi data pengguna ke service lain secara *real-time* dan asinkron.

### Fitur Utama:
- **Event-driven Identity Sync**: Mengirim event `identity.user_created` atau `identity.user_updated` saat profil berubah.
- **Webhook Dispatcher**: Mengirim payload JSON ke URL eksternal yang didaftarkan per tenant.

### Cara Menggunakan:
- Daftarkan endpoint webhook di tabel `webhook_endpoints`.
- Service penerima harus memverifikasi signature `X-Satu-Raya-Signature` untuk memastikan data berasal dari sumber yang sah.

---

## 6. API Management (Machine-to-Machine)

Akses API terprogram untuk integrasi antar sistem.

### Fitur Utama:
- **Service Clients**: Manajemen API Key dan Secret untuk service internal.
- **JWT Token Introspection**: Endpoint untuk memvalidasi token JWT yang dibawa oleh klien.

### Cara Menggunakan:
- Gunakan endpoint `POST /api/v1/token` untuk menukar API Key dengan JWT.
- Gunakan JWT tersebut pada header `Authorization: Bearer <token>` untuk mengakses API yang terlindungi.

---

## 7. UI Component Library (Base UI)

Kumpulan komponen visual standar untuk membangun halaman baru dengan cepat dan konsisten.

### Komponen Tersedia:
- `Card`: Kontainer dengan sudut membulat dan bayangan modern.
- `Button`: Tombol standar dengan dukungan varian (primary, outline, danger) dan integrasi form submit.
- `FormField` & `FormInput`: Abstraksi input form dengan penanganan error otomatis.
- `Badge`: Label status berwarna (Verified, Active, dll).

### Cara Menggunakan:
Gunakan helper render di dalam file ERB:
```erb
<%= render "shared/components/card" do %>
  <%= render "shared/components/button", label: "Klik Saya", variant: :primary %>
<% end %>
```
