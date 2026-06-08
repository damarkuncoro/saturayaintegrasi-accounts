# Reusable Accounts Docker Image

Dokumen ini menjelaskan langkah membuat `apps/accounts` dapat dipakai ulang untuk banyak project atau brand dengan satu Docker image yang sama.

Contoh target:

```text
accounts.satu-raya.dev
accounts.kacanggoreng.com
accounts.client-lain.com
```

Tujuan utamanya adalah menghindari pembangunan ulang fitur login, register, reset password, session, 2FA, OAuth, API client, consent, dan audit untuk setiap project baru.

## Status Saat Ini

Dokumen ini sekarang sudah menjadi runbook aktif, bukan hanya rencana awal.

Fondasi reusable accounts yang sudah tersedia di repo:

- `apps/accounts/Dockerfile` sudah memakai selective package copy agar image accounts hanya membawa package yang diperlukan.
- `apps/accounts/Gemfile` sudah memakai package internal `satu-raya-commons`, `satu-raya-system`, `satu-raya-identity`, `satu-raya-identity-client`, `satu-raya-identity-ui`, dan `satu-raya-ui`.
- `packages/identity-client` sudah berisi `SatuRayaIdentityClient::Identity::BrandConfig` dan `RedirectValidator`.
- `packages/identity-ui` sudah mulai memisahkan view identity dari package UI umum.
- `infra/compose/docker-compose.brand-example.yml` sudah menjadi contoh deployment brand kedua dengan image yang sama dan environment berbeda.

Konsekuensi status ini:

- Jangan membuat `BrandConfig` baru di `apps/accounts`; gunakan `SatuRayaIdentityClient::Identity::BrandConfig`.
- Jangan mengembalikan semua package ke image accounts; pertahankan selective copy agar image tetap murni identity platform.
- Jangan menambah view login/register ke `packages/commons`; gunakan `packages/identity-ui` atau brand view slot.
- `SatuRayaCommons::Identity::*` boleh tetap menjadi alias kompatibilitas sementara, tetapi implementasi baru sebaiknya masuk ke package yang lebih spesifik.

## Target Kondisi

Target akhir bukan membuat banyak fork accounts, melainkan satu image accounts yang dapat dipasang ulang untuk banyak brand.

```text
Source code sama
Docker image sama
Package boundary jelas
Brand dan domain lewat konfigurasi
Database/Redis/secret terisolasi per deployment
```

Accounts tetap menjadi service provider. Package internal hanya membantu memisahkan domain, client integration, dan presentation layer agar image accounts tidak menjadi terlalu besar atau terlalu terikat ke Satu Raya.

## Brand Hierarchy

Satu Raya Integrasi adalah umbrella company/platform.

Satu Raya adalah produk turunan dari Satu Raya Integrasi, bukan batas akhir platform identity.

```text
Satu Raya Integrasi
-> Identity Platform / Accounts
-> Satu Raya
-> Produk atau brand lain di masa depan
```

Implikasi:

- `accounts.satu-raya.dev` adalah deployment/brand pertama, bukan satu-satunya identitas produk.
- Docker image accounts sebaiknya netral terhadap brand.
- Package masa depan sebaiknya memakai naming umbrella Satu Raya Integrasi, bukan selalu Satu Raya.
- Satu Raya tetap boleh menjadi default brand untuk fase awal agar kompatibilitas tidak rusak.

Naming target jangka panjang:

```text
satu-raya-commons
satu-raya-system
satu-raya-identity
satu-raya-identity-client
satu-raya-identity-ui
satu-raya-ui
```

Naming saat ini seperti `satu-raya-commons` dipertahankan sementara demi kompatibilitas. Rename package dilakukan belakangan setelah reusable accounts dan package boundary stabil.

## Prinsip Utama

`apps/accounts` harus diperlakukan sebagai reusable identity platform.

Satu Raya adalah tenant atau brand pertama, bukan satu-satunya target aplikasi.

```text
Satu codebase accounts
Satu Docker image accounts
Banyak konfigurasi domain/brand/project
```

Yang berubah antar project bukan kodenya, melainkan konfigurasi:

- Domain login
- Nama brand
- Logo dan warna
- Database
- Redis/session store
- Secret key
- Email sender
- OAuth/OIDC client
- Allowed redirect URL
- Privacy policy dan terms URL

## Model Deploy Yang Direkomendasikan

Untuk project yang benar-benar berbeda, gunakan model berikut:

```text
Docker image sama
Environment berbeda
Database berbeda
Redis berbeda atau namespace berbeda
Secret berbeda
```

Contoh:

```text
accounts.satu-raya.dev
-> image: ghcr.io/satu-raya-integrasi/accounts:latest
-> database: satu_raya_accounts_production
-> redis namespace: satu-raya
-> brand: Satu Raya

accounts.kacanggoreng.com
-> image: ghcr.io/satu-raya-integrasi/accounts:latest
-> database: kacanggoreng_accounts_production
-> redis namespace: kacanggoreng
-> brand: Kacang Goreng
```

Model ini lebih aman karena data user dan kredensial tiap project terisolasi.

## Contoh Docker Compose

```yaml
services:
  accounts:
    image: ghcr.io/satu-raya-integrasi/accounts:latest
    restart: unless-stopped
    environment:
      RAILS_ENV: production
      APP_NAME: accounts
      APP_HOST: accounts.kacanggoreng.com
      APP_DOMAIN: kacanggoreng.com
      FORCE_SSL: "true"

      BRAND_NAME: Kacang Goreng
      BRAND_SLUG: kacanggoreng
      BRAND_PRIMARY_COLOR: "#D97706"
      BRAND_LOGO_URL: https://assets.kacanggoreng.com/logo.png
      BRAND_PRIVACY_URL: https://kacanggoreng.com/privacy
      BRAND_TERMS_URL: https://kacanggoreng.com/terms

      DATABASE_URL: postgres://accounts_user:password@postgres:5432/kacanggoreng_accounts_production
      REDIS_URL: redis://redis:6379/0
      REDIS_NAMESPACE: kacanggoreng_accounts

      SECRET_KEY_BASE: change-me
      JWT_ISSUER: https://accounts.kacanggoreng.com
      OIDC_ISSUER: https://accounts.kacanggoreng.com

      SMTP_FROM: no-reply@kacanggoreng.com
      SMTP_HOST: smtp.example.com
      SMTP_PORT: "587"
      SMTP_USERNAME: smtp-user
      SMTP_PASSWORD: smtp-password

      ALLOWED_REDIRECT_HOSTS: app.kacanggoreng.com,admin.kacanggoreng.com
      CORS_ALLOWED_ORIGINS: https://app.kacanggoreng.com,https://admin.kacanggoreng.com
```

## Environment Variable Minimal

Setiap deployment accounts minimal harus memiliki konfigurasi berikut:

| Variable | Fungsi |
| --- | --- |
| `APP_HOST` | Host utama accounts, contoh `accounts.kacanggoreng.com` |
| `APP_DOMAIN` | Root domain untuk cookie dan redirect, contoh `kacanggoreng.com` |
| `BRAND_NAME` | Nama brand yang tampil di UI dan email |
| `BRAND_SLUG` | Identifier pendek brand |
| `DATABASE_URL` | Database accounts untuk deployment tersebut |
| `REDIS_URL` | Redis untuk session, cache, dan queue |
| `SECRET_KEY_BASE` | Secret Rails, wajib unik per deployment |
| `JWT_ISSUER` | Issuer token JWT |
| `OIDC_ISSUER` | Issuer OIDC jika accounts menjadi identity provider |
| `SMTP_FROM` | Alamat email pengirim |
| `ALLOWED_REDIRECT_HOSTS` | Daftar domain app yang boleh menerima redirect login |
| `CORS_ALLOWED_ORIGINS` | Daftar origin frontend/API client yang dipercaya |
| `SESSION_COOKIE_NAME` | Nama cookie Rails session, sebaiknya unik per brand/deployment |
| `AUTH_SESSION_COOKIE_NAME` | Nama cookie untuk record login accounts, sebaiknya unik per brand/deployment |
| `TRUSTED_DEVICE_COOKIE_NAME` | Nama cookie trusted device/MFA, sebaiknya unik per brand/deployment |
| `SESSION_COOKIE_DOMAIN` | Domain cookie session; gunakan domain project, bukan domain global lintas brand |
| `BRAND_SUPPORT_EMAIL` | Email support yang ditampilkan di UI dan email |

Catatan implementasi:

- Sumber konfigurasi brand saat ini adalah `SatuRayaIdentityClient::Identity::BrandConfig`.
- Default masih mengarah ke Satu Raya untuk kompatibilitas development dan deployment awal.
## Checklist Kesiapan Reusable Image

- [x] Package identity-client tersedia sebagai tempat `BrandConfig` dan `RedirectValidator`.
- [x] Package identity-ui tersedia sebagai tempat view identity.
- [x] Dockerfile accounts memakai selective package copy.
- [x] Contoh compose brand kedua tersedia di `infra/compose/docker-compose.brand-example.yml`.
- [x] Tidak ada hardcode `satu-raya.dev` yang memengaruhi production brand lain.
- [x] Tidak ada hardcode `jobs.satu-raya.dev` untuk default redirect production.
- [x] Nama brand dibaca dari `SatuRayaIdentityClient::Identity::BrandConfig`.
- [x] Logo dan warna dibaca dari config.
- [x] Email sender dibaca dari config.
- [x] Cookie domain dan cookie name dibaca dari config.
- [x] Allowed redirect hosts dibaca dari config.
- [x] CORS origin dibaca dari config.
- [x] JWT issuer dibaca dari config.
- [x] OIDC issuer dibaca dari config.
- [x] Database dapat diganti via `DATABASE_URL`.
- [x] Redis dapat diganti via `REDIS_URL`.
- [x] Secret unik per deployment.
- [x] Migration bisa dijalankan per database deployment.
- [x] Health check dan readiness check tersedia.
- [x] Build image accounts lolos tanpa membawa package bisnis yang tidak diperlukan.
- [x] Smoke test accounts berjalan untuk env Satu Raya dan contoh brand kedua.
- [x] Model Identity::User bersifat "Pure IAM" tanpa asosiasi hardcoded ke domain bisnis lain.

## Prinsip Pure IAM Architecture

Agar `apps/accounts` benar-benar reusable, model `Identity::User` harus murni mengelola identitas dan akses. Model ini tidak boleh memiliki ketergantungan (hard-coupled associations) ke domain bisnis lain seperti Finance, Profile, atau Communication.

### Mekanisme Extension (Cross-Package Hook)

Untuk tetap mendukung fitur yang membutuhkan relasi ke User (seperti profil atau dompet), gunakan mekanisme hook `ActiveSupport.on_load(:identity_user)` di dalam masing-masing package engine.

**1. Di dalam Model User (Package Identity):**

```ruby
class Identity::User < ApplicationRecord
  # ... IAM logic ...
  
  # Trigger hook agar modul lain bisa mendaftarkan diri
  ActiveSupport.run_load_hooks(:identity_user, self)
end
```

**2. Di dalam Modul Bisnis (Contoh: Profile):**

```ruby
# packages/profile/lib/satu_raya_profile/engine.rb
initializer "satu_raya_profile.identity_user_extension" do
  ActiveSupport.on_load(:identity_user) do
    has_one :worker_profile, class_name: "Profile::WorkerProfile", dependent: :destroy
    # ... callback atau logika tambahan ...
  end
end
```

Keuntungan pendekatan ini:
- **Zero-coupling**: Package `identity` tidak tahu siapa yang menggunakannya.
- **Selective Loading**: Asosiasi hanya muncul jika package bisnis tersebut dimuat dalam aplikasi.
- **Clean Image**: Image `accounts` tetap ringan karena tidak memuat model bisnis yang tidak relevan.

## Independent Identity Client SDK

`packages/identity-client` telah dirancang agar sepenuhnya independen dan dapat digunakan oleh berbagai aplikasi (baik internal maupun eksternal) tanpa ketergantungan pada model database `accounts`.

Fitur Utama SDK:
- **Konfigurasi Fleksibel**: Dapat dikonfigurasi via `SatuRayaIdentityClient.configure` untuk mengatur `accounts_url`, `client_id`, `client_secret`, serta `jwt_secret` dan `algorithm`.
- **API Authentication Independen**: Concern `ApiAuthentication` dapat memverifikasi JWT tanpa memerlukan model `Identity::User` lokal. Jika model user tidak ditemukan, ia akan menyediakan objek user ringan berbasis data dari token.
- **Tenancy Awareness**: Otomatis mendeteksi tenant dari token JWT dan mengatur `System::Current.tenant`.
- **SSO Helper**: Menyediakan helper untuk navigasi antar layanan (`accounts_url_for`, `jobs_url_for`, dll) yang kini dipisahkan ke dalam package `satu-raya-navigation`.

## Service Discovery & Navigation Package

Package `satu-raya-navigation` (di `packages/navigation`) dipisahkan agar logika navigasi antar-subdomain tidak mengotori package identity. Package ini menyediakan:
- Helper URL dinamis yang sadar akan domain brand.
- `NavigationHelpers` concern yang dapat di-include di controller mana pun.
- Dukungan untuk navigasi lintas layanan: Accounts, Jobs, Business, dan Standardization.
## Keputusan Arsitektur

Gunakan satu Docker image accounts untuk semua brand.

Untuk project berbeda, gunakan database berbeda. Multi-tenant dalam satu database tetap mungkin, tetapi sebaiknya dipakai hanya jika semua brand benar-benar berada dalam satu platform operasional yang sama.

Dengan pendekatan ini, project baru tidak perlu membangun ulang identity system. Project baru cukup membuat konfigurasi deployment dan mendaftarkan OAuth/OIDC client.

## Kendala Yang Mungkin Dihadapi

### 1. Hardcode Brand Dan Domain

Masalah:

View, route, mailer, script, seed, dan redirect mungkin masih menyebut `Satu Raya`, `satu-raya.dev`, `jobs.satu-raya.dev`, atau `business.satu-raya.dev`.

Dampak:

- `accounts.kacanggoreng.com` masih menampilkan Satu Raya.
- Redirect user bisa menuju domain yang salah.
- Email reset password bisa memakai nama brand yang salah.

Mitigasi:

- Gunakan `SatuRayaIdentityClient::Identity::BrandConfig`.
- Tambahkan helper view untuk brand name/logo/color.
- Tambahkan test yang menjalankan request dengan `APP_DOMAIN=kacanggoreng.com`.
- Tambahkan scan CI untuk string domain yang tidak boleh hardcode di `apps/accounts`.

### 2. Cookie Domain Dan Session Bocor Antar Brand

Masalah:

Cookie dengan domain terlalu luas atau salah domain dapat membuat browser mengirim session ke aplikasi yang tidak semestinya.

Dampak:

- User Satu Raya terlihat login di brand lain.
- Logout tidak konsisten.
- Risiko keamanan lintas project.

Mitigasi:

- Untuk database/project terpisah, gunakan cookie domain sesuai root domain project.
- Jangan gunakan cookie domain global yang tidak spesifik.
- Gunakan nama cookie yang dapat dikonfigurasi: `SESSION_COOKIE_NAME`, `AUTH_SESSION_COOKIE_NAME`, dan `TRUSTED_DEVICE_COOKIE_NAME`.
- Test manual dua domain dalam browser yang sama.

### 3. Redirect Injection

Masalah:

Parameter `return_to` dapat disalahgunakan untuk mengarahkan user ke domain penyerang.

Dampak:

- Phishing setelah login.
- Token atau code OAuth bisa bocor jika validasi redirect lemah.

Mitigasi:

- Gunakan allowlist host.
- Untuk OIDC, wajibkan redirect URI exact match.
- Jangan menerima wildcard redirect URI untuk production.
- Simpan attempt redirect gagal di audit log.

### 4. Tenant Resolution Salah

Masalah:

Tenant bisa diambil dari `System::Tenant.first` atau fallback yang terlalu longgar.

Dampak:

- User dibuat di tenant yang salah.
- Email yang sama bentrok atau terlihat di brand lain.
- Audit log salah tenant.

Mitigasi:

- Resolve tenant berdasarkan host request.
- Jika tenant tidak ditemukan, tampilkan error konfigurasi, bukan fallback diam-diam.
- Seed tenant default hanya untuk development/test.
- Tambahkan unique index email per tenant, yang saat ini sudah sesuai arah skema.

### 5. Database Migration Per Brand

Masalah:

Jika ada banyak database brand, migrasi harus dijalankan konsisten ke semua deployment.

Dampak:

- Satu brand berhasil deploy, brand lain gagal karena schema tertinggal.
- Rollback lebih rumit.

Mitigasi:

- Pakai migration job per deployment.
- Catat versi image dan schema migration per brand.
- Jalankan migration sebelum traffic diarahkan ke image baru.
- Untuk perubahan destruktif, gunakan pola expand-contract.

### 6. Secret Dan Key Management

Masalah:

`SECRET_KEY_BASE`, JWT secret, OAuth client secret, dan SMTP password tidak boleh sama lintas project.

Dampak:

- Kebocoran satu project dapat memengaruhi project lain.
- Token bisa diterima di issuer yang salah jika secret digunakan ulang sembarangan.

Mitigasi:

- Secret unik per deployment.
- Gunakan secret manager, bukan file `.env` production yang tersebar.
- Rotasi secret punya runbook.
- Token selalu validasi `iss`, `aud`, `exp`, dan `jti`.

### 7. OIDC Lebih Sulit Dari Login Biasa

Masalah:

OIDC membutuhkan banyak detail keamanan: authorization code, PKCE, refresh token, revocation, consent, scope, discovery, JWKS, dan redirect URI exact match.

Dampak:

- Implementasi setengah matang bisa lebih berbahaya daripada tidak ada OIDC.
- Integrasi client menjadi tidak kompatibel dengan library umum.

Mitigasi:

- Untuk awal, internal SSO dulu.
- Implementasi OIDC sebagai fase terpisah.
- Pertimbangkan gem/protocol library yang matang.
- Buat conformance checklist minimal sebelum dipakai project eksternal.

### 8. Branding Tidak Hanya Logo

Masalah:

Branding menyentuh UI, email, legal text, privacy policy, terms, sender domain, dan support contact.

Dampak:

- User bingung karena melihat nama brand campur.
- Risiko legal jika policy/terms salah.

Mitigasi:

- Pastikan `SatuRayaIdentityClient::Identity::BrandConfig` mencakup legal URL dan support email.
- Pisahkan template email dengan variable brand.
- Jangan hardcode copywriting brand di view auth.
- Untuk landing page marketing, pertimbangkan per brand route atau disable dari accounts.

### 9. Kustomisasi View Per Klien

Masalah:

Klien mungkin ingin login/register page, email verification page, reset password page, dashboard akun, atau consent screen terlihat sesuai karakter project mereka.

Contoh kebutuhan:

```text
Satu Raya:
- Nuansa workforce/job platform.
- Copywriting tentang pekerja dan perusahaan.
- Redirect utama ke jobs/business.

Kacang Goreng:
- Nuansa brand makanan/retail.
- Copywriting lebih ringan dan consumer-friendly.
- Redirect utama ke app/admin Kacang Goreng.
```

Dampak:

- Jika semua view diubah langsung, kode cepat bercampur antar brand.
- Jika dibuat fork per klien, maintenance security auth menjadi berat.
- Update keamanan login harus diulang di banyak project.
- QA menjadi sulit karena variasi UI tidak terkendali.

Strategi:

- Pisahkan auth logic dari presentational view.
- Buat level kustomisasi bertahap, dari paling aman sampai paling fleksibel.
- Jangan izinkan klien mengubah logic login/register langsung.
- Semua view custom tetap memakai controller, route, policy, dan form contract yang sama.

Level kustomisasi yang disarankan:

| Level | Nama | Cocok Untuk | Risiko |
| --- | --- | --- | --- |
| 1 | Theme config | Logo, warna, font, nama brand | Rendah |
| 2 | Copy config | Teks headline, subtitle, CTA, support text | Rendah |
| 3 | Layout variant | Pilihan layout login/register yang sudah disediakan | Sedang |
| 4 | Partial override | Klien punya partial sendiri untuk bagian tertentu | Sedang |
| 5 | Brand view pack | Satu paket view khusus per brand | Tinggi |

### Level 1: Theme Config

Gunakan environment variable atau tabel brand settings.

Contoh:

```text
BRAND_NAME=Kacang Goreng
BRAND_LOGO_URL=https://assets.kacanggoreng.com/logo.png
BRAND_PRIMARY_COLOR=#D97706
BRAND_ACCENT_COLOR=#16A34A
BRAND_FONT_FAMILY=Inter
```

Cocok untuk tahap awal karena tidak mengubah struktur view.

### Level 2: Copy Config

Copywriting yang sering berubah sebaiknya bisa dikonfigurasi.

Contoh:

```text
BRAND_LOGIN_TITLE=Masuk ke Kacang Goreng
BRAND_LOGIN_SUBTITLE=Kelola akun dan layanan Anda di satu tempat.
BRAND_REGISTER_TITLE=Buat akun baru
BRAND_SUPPORT_EMAIL=support@kacanggoreng.com
```

Untuk Rails, copy bisa ditaruh di I18n per brand:

```text
config/locales/brands/satu-raya.id.yml
config/locales/brands/kacanggoreng.id.yml
```

Kemudian resolver memilih translation scope berdasarkan `BRAND_SLUG`.

### Level 3: Layout Variant

Sediakan beberapa layout resmi yang aman.

Contoh:

```text
AUTH_LAYOUT_VARIANT=centered
AUTH_LAYOUT_VARIANT=split
AUTH_LAYOUT_VARIANT=compact
AUTH_LAYOUT_VARIANT=enterprise
```

Semua variant tetap memakai form partial dan security behavior yang sama.

Aturan:

- Variant hanya mengubah layout visual.
- Field wajib tetap sama.
- CSRF token, method, route, dan validation error tetap dari shared partial.
- OAuth button tetap memakai daftar provider yang dikonfigurasi.

### Level 4: Partial Override

Jika klien butuh area khusus, gunakan slot/partial override.

Contoh struktur:

```text
app/views/identity/sessions/new.html.erb
app/views/identity/registrations/new.html.erb
app/views/identity/password_resets/new.html.erb

app/views/brands/satu-raya/identity/_hero.html.erb
app/views/brands/kacanggoreng/identity/_hero.html.erb
app/views/brands/kacanggoreng/identity/_footer.html.erb
```

View utama tetap shared:

```erb
<%= render_brand_partial("identity/hero") %>
<%= render "identity/shared/login_form" %>
<%= render_brand_partial("identity/footer") %>
```

Jika brand partial tidak ada, fallback ke default.

Aturan:

- Partial custom tidak boleh membuat form login sendiri jika tidak perlu.
- Partial custom tidak boleh menentukan redirect langsung.
- Partial custom tidak boleh membaca secret.
- Partial custom hanya untuk konten visual, trust badge, legal links, ilustrasi, dan copy tambahan.

### Level 5: Brand View Pack

Gunakan hanya untuk klien besar yang benar-benar perlu pengalaman visual berbeda.

Contoh:

```text
app/views/brand_packs/kacanggoreng/identity/sessions/new.html.erb
app/views/brand_packs/kacanggoreng/identity/registrations/new.html.erb
app/views/brand_packs/kacanggoreng/layouts/auth.html.erb
```

Aturan:

- Brand view pack harus melewati review keamanan.
- Form contract harus tetap kompatibel.
- Test request dan system test wajib jalan untuk setiap brand pack.
- Jangan duplikasi controller.
- Jangan duplikasi use case.
- Jangan ubah route per brand kecuali benar-benar diperlukan.

## Arsitektur View Yang Disarankan

Pisahkan view menjadi tiga lapisan:

```text
Shared auth shell
-> Menyediakan struktur halaman, flash, CSRF, form container, error rendering.

Shared secure form partials
-> Login form, register form, reset password form, MFA form, consent form.

Brand presentation slots
-> Hero, illustration, trust badges, footer, support text, legal links.
```

Struktur file yang disarankan:

```text
apps/accounts/app/views/identity/shared/_login_form.html.erb
apps/accounts/app/views/identity/shared/_register_form.html.erb
apps/accounts/app/views/identity/shared/_reset_password_form.html.erb
apps/accounts/app/views/identity/shared/_consent_form.html.erb

apps/accounts/app/views/identity/sessions/new.html.erb
apps/accounts/app/views/identity/registrations/new.html.erb

apps/accounts/app/views/brands/default/identity/_hero.html.erb
apps/accounts/app/views/brands/default/identity/_footer.html.erb
apps/accounts/app/views/brands/satu-raya/identity/_hero.html.erb
apps/accounts/app/views/brands/kacanggoreng/identity/_hero.html.erb
```

Helper render:

```ruby
module BrandViewHelper
  def render_brand_partial(name, locals = {})
    brand_path = "brands/#{SatuRayaIdentityClient::Identity::BrandConfig.slug}/#{name}"
    default_path = "brands/default/#{name}"

    if lookup_context.exists?(brand_path, [], true)
      render brand_path, locals: locals
    else
      render default_path, locals: locals
    end
  end
end
```

## Batas Aman Kustomisasi View

Yang boleh dikustomisasi:

- Logo
- Warna
- Font
- Hero section
- Ilustrasi
- Headline dan subtitle
- Legal links
- Support contact
- Trust badge
- Footer
- Email copy

Yang tidak boleh dikustomisasi bebas:

- Password verification logic
- Session creation logic
- MFA challenge logic
- Token generation logic
- Redirect validation logic
- OAuth/OIDC callback validation
- CSRF behavior
- Audit logging
- Tenant resolution
- Rate limiting

## Test Untuk View Custom

Setiap brand custom minimal harus lolos test berikut:

```text
GET /login menampilkan brand yang benar
GET /register menampilkan brand yang benar
POST /login tetap memakai controller yang sama
POST /register tetap membuat user di tenant yang benar
Reset password email memakai brand yang benar
Invalid return_to tidak dipakai
Allowed return_to tetap jalan
CSRF token tersedia di semua form
OAuth button hanya tampil jika provider aktif
Mobile layout tidak rusak
```

Jika brand memakai view pack level 5, tambahkan screenshot/system test per brand.

### 10. Email Deliverability

Masalah:

Domain baru perlu SPF, DKIM, DMARC, dan sender reputation.

Dampak:

- Email verifikasi dan reset password masuk spam.
- User gagal onboarding.

Mitigasi:

- Konfigurasi SMTP per brand.
- Verifikasi DNS sebelum go-live.
- Tambahkan monitoring bounce dan delivery failure.
- Siapkan fallback support flow.

### 11. Observability Dan Debugging

Masalah:

Satu image dipakai banyak brand, sehingga log harus bisa dibedakan.

Dampak:

- Sulit mengetahui error terjadi di brand mana.
- Incident response lebih lambat.

Mitigasi:

- Tambahkan `brand_slug`, `tenant_id`, `request_host`, dan `request_id` pada log.
- Metric diberi label brand/deployment.
- Audit log wajib menyimpan tenant dan actor.
- Dashboard monitoring dipisah per deployment.

## Prioritas Risiko

| Risiko | Tingkat | Alasan |
| --- | --- | --- |
| Redirect injection | Tinggi | Bisa langsung dipakai untuk phishing atau token leakage |
| Cookie/session bocor antar brand | Tinggi | Berdampak langsung ke keamanan akun |
| Tenant resolution salah | Tinggi | Bisa mencampur data user |
| Secret digunakan ulang | Tinggi | Kebocoran satu project berdampak lintas project |
| Hardcode brand/domain | Sedang | Merusak UX dan dapat menyebabkan redirect salah |
| View custom terlalu bebas | Sedang | Bisa merusak form contract atau melewati security behavior |
| Migrasi database tidak seragam | Sedang | Bisa menyebabkan downtime per brand |
| Email deliverability | Sedang | Menghambat onboarding dan reset password |
| OIDC compliance | Sedang | Integrasi eksternal bisa gagal atau tidak aman |

## Strategi Gem Internal

Repo ini sudah memiliki beberapa gem internal. Strategi sekarang bukan lagi "apakah perlu membuat gem sendiri", melainkan menjaga agar tiap gem tidak melebar ke tanggung jawab service lain.

Gem/package yang relevan saat ini:

| Package | Gem | Status | Peran |
| --- | --- | --- | --- |
| `packages/commons` | `satu-raya-commons` | Ada | Primitive netral lintas app |
| `packages/system` | `satu-raya-system` | Ada | Domain system/platform yang bukan identity |
| `packages/identity` | `satu-raya-identity` | Ada | Domain identity internal |
| `packages/identity-client` | `satu-raya-identity-client` | Ada | Config, redirect validator, dan calon SDK client |
| `packages/identity-ui` | `satu-raya-identity-ui` | Ada | View dan helper identity |
| `packages/ui` | `satu-raya-ui` | Ada | Komponen UI shared non-auth |

Jadi strategi yang dibutuhkan adalah menata batas antara:

- Logic yang tetap berada di `apps/accounts`.
- Logic reusable netral yang masuk ke `satu-raya-commons`.
- Logic domain identity yang masuk ke `satu-raya-identity`.
- Logic client integration yang masuk ke `satu-raya-identity-client`.
- Logic view identity yang masuk ke `satu-raya-identity-ui`.

## Apakah Perlu Membuat Gem Sendiri?

Jawaban pendek: perlu, tetapi bertahap.

Untuk tahap sekarang, gem utama sudah dibuat. Fokus berikutnya adalah mematangkan kontrak dan menghindari overlap.

Jangan membuat gem tambahan sebelum ada kebutuhan nyata. Yang sudah ada cukup untuk fase reusable accounts.

Gunakan Docker image untuk menjalankan service `accounts`.

Gunakan gem untuk membagikan library kecil yang dibutuhkan app lain agar bisa berkomunikasi aman dengan `accounts`.

```text
Docker image accounts
-> Menjalankan identity provider: login, register, session, MFA, OIDC, consent.

Gem commons/client
-> Dipasang di app lain: verifikasi token, helper redirect, current user resolver, HMAC/JWT client.
```

## Yang Cocok Masuk Gem

Masukkan ke gem hanya logic yang benar-benar reusable dan tidak bergantung pada UI/accounts runtime.

Kandidat untuk `satu-raya-commons`:

- JWT encode/decode dan validasi issuer/audience.
- HMAC signer/verifier untuk internal API.
- Current user resolver untuk app Rails lain.
- Middleware auth untuk membaca bearer token.
- OIDC client helper untuk app yang memakai "Login with Accounts".
- Redirect URL validator.
- Tenant/domain resolver interface.
- Shared error codes.
- Shared audit event schema.
- Shared API response object.

Kandidat untuk `satu-raya-identity-client`:

```text
satu-raya-identity-client
```

Isi gem ini fokus untuk aplikasi yang ingin login via accounts:

- Generate authorization URL.
- Exchange authorization code ke token.
- Fetch `/oauth/userinfo`.
- Verify ID token.
- Refresh token.
- Revoke token.
- Rails controller concern untuk callback.
- Rack middleware untuk protected route.

## Yang Tidak Boleh Masuk Gem

Jangan masukkan bagian ini ke gem client/shared:

- Password verification flow.
- Session creation di accounts.
- MFA challenge internal.
- Controller login/register accounts.
- View login/register.
- Consent approval UI.
- Database model penuh `Identity::User` untuk app eksternal.
- Secret production.
- Business-specific redirect seperti `jobs.satu-raya.dev`.

Alasannya: bagian tersebut adalah tanggung jawab identity provider, bukan library client.

Jika dipindahkan ke gem, app lain bisa tergoda membuat login sendiri lagi, dan tujuan reuse menjadi kabur.

## Lapisan Gem Yang Disarankan

### 1. `satu-raya-commons`

Status: sudah ada.

Peran:

- Shared primitives.
- Shared security utilities.
- Shared response/error schema.
- Shared DDD/value objects yang benar-benar lintas app.

Contoh isi:

```text
SatuRayaCommons::Security::HmacSigner
SatuRayaCommons::Security::JwtCodec
SatuRayaCommons::Identity::TokenVerifier
SatuRayaCommons::Identity::RedirectValidator
SatuRayaCommons::System::CurrentContext
```

### 2. `satu-raya-identity-client`

Status: sudah ada sebagai package internal versi awal.

Saat ini sudah berisi `BrandConfig` dan `RedirectValidator`. Langkah berikutnya adalah mematangkan client SDK jika sudah ada app non-accounts yang memakai OIDC flow yang sama.

Peran:

- Client SDK untuk app yang memakai accounts sebagai OIDC provider.
- Menghindari duplikasi callback OAuth/OIDC di banyak app.

Contoh pemakaian di app lain:

```ruby
SatuRayaIdentityClient.configure do |config|
  config.issuer = ENV.fetch("ACCOUNTS_ISSUER")
  config.client_id = ENV.fetch("ACCOUNTS_CLIENT_ID")
  config.client_secret = ENV.fetch("ACCOUNTS_CLIENT_SECRET")
  config.redirect_uri = ENV.fetch("ACCOUNTS_REDIRECT_URI")
end
```

### 3. Brand/View Pack Gem

Status: opsional dan hanya untuk klien besar.

Jika suatu klien ingin view custom yang sangat besar, pertimbangkan brand view pack sebagai gem atau engine terpisah.

Contoh:

```text
kacanggoreng-accounts-theme
```

Isi:

- View partial khusus brand.
- Asset brand.
- Locale/copy brand.
- Layout variant brand.

Aturan:

- Gem theme tidak boleh membawa auth logic.
- Gem theme tidak boleh membawa migration identity.
- Gem theme tidak boleh override controller security.
- Gem theme hanya presentation layer.

## Kapan Membuat Gem Baru?

Buat gem baru hanya jika minimal satu kondisi ini terpenuhi:

- Kode yang sama sudah dipakai oleh minimal dua app berbeda.
- Kode tersebut punya kontrak API yang stabil.
- Kode tersebut bisa dites tanpa menjalankan full accounts app.
- Kode tersebut tidak membawa data model yang seharusnya dimiliki service tertentu.
- Kode tersebut membuat integrasi app baru jauh lebih cepat.

Jangan membuat gem baru jika:

- Kebutuhannya baru satu app.
- API masih sering berubah.
- Kode masih sangat bergantung pada controller/view accounts.
- Tujuannya hanya memindahkan folder agar terlihat rapi.

## Versioning Gem

Gunakan semantic versioning:

```text
MAJOR.MINOR.PATCH
```

Aturan:

- `PATCH`: bug fix tanpa perubahan API.
- `MINOR`: fitur baru backward-compatible.
- `MAJOR`: breaking change.

Untuk monorepo internal, versi gem tetap penting karena Docker image dan app client bisa bergerak dengan kecepatan berbeda.

Contoh:

```text
satu-raya-commons 1.2.3
satu-raya-identity-client 0.1.0
```

## Risiko Membuat Gem Terlalu Cepat

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Abstraksi terlalu dini | Gem sering berubah dan menghambat development | Tunggu sampai ada dua pemakai nyata |
| Logic auth tersebar | Security review lebih sulit | Auth provider logic tetap di accounts |
| Model database bocor ke app lain | Service boundary rusak | App lain hanya menerima token/userinfo |
| Version mismatch | App client tidak cocok dengan accounts | Pakai semantic versioning dan compatibility matrix |
| Gem menjadi terlalu besar | Commons berubah menjadi tempat semua hal | Buat aturan ownership dan review |

## Compatibility Matrix

Karena gem client sudah ada, dokumentasikan kompatibilitasnya setiap kali image accounts dan package identity berubah.

Contoh:

| Accounts Image | `satu-raya-commons` | `satu-raya-identity-client` | Status |
| --- | --- | --- | --- |
| `accounts:1.0.x` | `1.0.x` | `0.1.x` | Config, redirect validator, internal SSO |
| `accounts:1.1.x` | `1.1.x` | `0.2.x` | OIDC pilot |
| `accounts:1.2.x` | `1.2.x` | `0.3.x` | OIDC stable |

## Rekomendasi Praktis

Untuk fase sekarang:

1. Jangan buat gem tambahan dulu.
2. Rapikan `satu-raya-commons` agar hanya berisi shared utility yang jelas.
3. Matangkan `satu-raya-identity-client` sebagai rumah config, redirect validator, dan calon OIDC client SDK.
4. Matangkan `satu-raya-identity-ui` sebagai rumah view auth yang aman dikustomisasi.
5. Pastikan `accounts` dapat menjadi Docker image reusable.
6. Jika klien besar butuh UI custom berat, pertimbangkan brand/theme gem atau Rails engine khusus presentation layer.

Dengan strategi ini, Docker image tetap menjadi unit deployment utama, sedangkan gem menjadi alat integrasi dan reuse kode antar app.

## Strategi Pemecahan `packages/commons`

`packages/commons` saat ini terlalu lebar jika dipandang sebagai fondasi reusable accounts jangka panjang.

Masalah utamanya bukan karena `commons` besar, tetapi karena ownership-nya mulai bercampur:

- Security primitive.
- Identity domain.
- Controller concern.
- UI/layout shared.
- Seeds.
- Use case identity.
- Use case domain lain seperti attendance, training, compliance, dan payroll.
- Model lintas aplikasi.

Untuk monorepo tahap awal, kondisi ini masih wajar. Tetapi jika `accounts` akan menjadi identity platform reusable untuk banyak brand atau project, batas package perlu dibuat lebih tegas.

## Prinsip Pemisahan Package

Gunakan prinsip berikut:

- `commons` harus netral dan kecil.
- `identity` boleh tahu tentang akun, user, session, MFA, token, dan consent.
- `identity-client` hanya membantu app lain berbicara dengan accounts.
- `accounts` tetap menjadi service provider, bukan library.
- UI brand custom jangan masuk `commons`.
- Domain bisnis seperti jobs, attendance, payroll, training, dan compliance tidak boleh bercampur ke identity package.

Target struktur:

```text
packages/commons
packages/system
packages/identity
packages/identity-client
packages/identity-ui
packages/ui
apps/accounts
```

## Target Peran Tiap Package

### `packages/commons`

Peran:

- Utility netral lintas semua app.
- Security primitive yang tidak spesifik accounts.
- Error/response schema.
- Logging.
- Cache helper.
- Event bus primitive.
- HMAC signer/verifier.
- Base audit event schema.

Yang boleh berada di sini:

```text
SatuRayaCommons::Security::HmacSigner
SatuRayaCommons::Security::JwtCodec
SatuRayaCommons::ApiResponder
SatuRayaCommons::ErrorHandler
SatuRayaCommons::Cache
SatuRayaCommons::EventBus
SatuRayaCommons::Logging
```

Yang sebaiknya keluar dari sini:

- Model `Identity::*`.
- Use case identity yang mengubah password, MFA, session, atau user.
- View/layout auth.
- Brand config accounts.
- OIDC provider/client logic.
- Attendance/training/payroll/compliance use cases.

### `packages/identity`

Peran:

- Domain identity reusable.
- Model dan use case identity yang memang dipakai accounts dan app internal.
- Session, MFA, token, consent, API client, dan permission metadata.

Yang cocok berada di sini:

```text
Identity::User
Identity::Session
Identity::UserPermission
Identity::ApiClient
Identity::SsoClientConfiguration
Identity::UserConsent
Identity::TrustedDevice
Identity::UserPasskey
UseCases::Identity::Login
UseCases::Identity::Register
UseCases::Identity::VerifyMfa
UseCases::Identity::RevokeSession
```

Catatan:

`packages/identity` boleh menjadi Rails engine internal, tetapi jangan menjadi aplikasi login sendiri. Provider login tetap `apps/accounts`.

### `packages/identity-client`

Peran:

- SDK untuk app lain yang ingin memakai accounts.
- Tidak menyimpan password.
- Tidak membuat session accounts sendiri.
- Tidak memuat model penuh `Identity::User`.

Yang cocok berada di sini:

```text
SatuRayaIdentityClient::TokenVerifier
SatuRayaIdentityClient::AuthorizationUrl
SatuRayaIdentityClient::CallbackHandler
SatuRayaIdentityClient::UserinfoClient
SatuRayaIdentityClient::Middleware
SatuRayaIdentityClient::CurrentUserResolver
```

Contoh pemakaian:

```ruby
SatuRayaIdentityClient.configure do |config|
  config.issuer = ENV.fetch("ACCOUNTS_ISSUER")
  config.client_id = ENV.fetch("ACCOUNTS_CLIENT_ID")
  config.client_secret = ENV.fetch("ACCOUNTS_CLIENT_SECRET")
  config.redirect_uri = ENV.fetch("ACCOUNTS_REDIRECT_URI")
end
```

Catatan saat ini:

- `SatuRayaIdentityClient::Identity::BrandConfig` sudah berada di package ini.
- `SatuRayaIdentityClient::Identity::RedirectValidator` sudah berada di package ini.
- Alias kompatibilitas `SatuRayaCommons::Identity::*` boleh tetap ada sementara.

### `packages/identity-ui`

Peran:

- Presentation layer untuk identity/auth.
- View login, register, reset password, MFA, consent, dan email identity.
- Brand presentation slots.
- Helper render brand partial.

Yang cocok berada di sini:

```text
identity/shared/_login_form
identity/shared/_register_form
identity/password_resets/*
identity/two_factor_challenges/*
identity/oauth/authorize
brands/default/identity/_hero
brands/default/identity/_background
```

Yang tidak cocok:

- Password verification logic.
- Session creation logic.
- Token generation.
- Redirect validation.
- Tenant resolution.
- Business-specific dashboard.

### `packages/ui`

Peran:

- Komponen UI shared yang bukan auth logic.
- Layout primitive.
- Form components.
- Flash components.
- Navigation components yang netral.

Yang cocok berada di sini:

```text
Shared::Components::Button
Shared::Components::FormField
Shared::Components::Flash
Shared::Components::Navbar
Shared::Components::Footer
```

Yang tidak cocok:

- Login form logic.
- Password reset flow.
- MFA challenge behavior.
- Brand-specific hero.
- Copywriting khusus Satu Raya/Kacang Goreng.

### `apps/accounts`

Peran:

- Identity provider yang berjalan sebagai Docker image.
- Login/register UI.
- Password reset UI.
- MFA UI.
- Consent screen.
- OAuth/OIDC provider endpoint.
- Mailer identity.
- Brand rendering.
- Admin/client management UI.

Yang harus tetap di sini:

```text
Identity::SessionsController
Identity::RegistrationsController
Identity::PasswordResetsController
Identity::TwoFactorChallengesController
OAuth/OIDC provider controllers
accounts-specific routes
accounts-specific mailers
accounts-specific views
brand presentation slots
```

## Peta Migrasi Dari Struktur Sekarang

Jangan pindahkan semua sekaligus.

Gunakan migrasi bertahap:

### Tahap 1: Inventarisasi

Tandai isi `packages/commons` berdasarkan kategori:

```text
shared-neutral
identity-domain
identity-client
ui-shared
business-domain
unclear
```

Output:

- Dokumen inventory.
- Daftar file yang tetap di commons.
- Daftar file kandidat pindah ke identity.
- Daftar file kandidat pindah ke ui.
- Daftar file kandidat keluar dari commons karena domain-specific.

### Tahap 2: Buat Boundary Tanpa Memindahkan File

Tambahkan namespace dan aturan import lebih jelas.

Contoh:

```text
SatuRayaCommons::Security
SatuRayaCommons::Api
SatuRayaCommons::Observability
SatuRayaIdentity
SatuRayaIdentityClient
SatuRayaUi
```

Pada tahap ini, boleh membuat module baru tetapi belum perlu memindahkan semua file.

Tujuannya agar kode baru tidak makin menambah isi `commons` yang campur.

### Tahap 3: Ekstrak `packages/identity`

Pindahkan identity domain secara bertahap:

```text
packages/commons/app/models/identity
-> packages/identity/app/models/identity

packages/commons/app/core/use_cases/identity
-> packages/identity/app/core/use_cases/identity

packages/commons/app/core/services/identity
-> packages/identity/app/core/services/identity
```

Aturan:

- Pindah file satu kelompok kecil.
- Pastikan autoload path tetap benar.
- Jalankan request spec accounts.
- Jalankan smoke app internal.
- Jangan ubah behavior public dalam commit yang sama dengan perpindahan besar.

### Tahap 4: Ekstrak `packages/ui`

Pindahkan shared UI yang netral:

```text
packages/commons/app/views/shared/components
-> packages/ui/app/views/shared/components
```

Aturan:

- UI shared boleh dipakai accounts/jobs/business.
- Brand-specific view tetap di app masing-masing.
- Auth form security tetap di accounts atau identity package, bukan UI package.

### Tahap 5: Buat `packages/identity-client`

Status: package ini sudah dibuat.

Langkah pematangan:

- Pertahankan `BrandConfig` dan `RedirectValidator` di sini.
- Tambahkan token verifier saat OIDC token mulai dipakai app lain.
- Tambahkan authorization URL builder saat app eksternal pertama dibuat.
- Tambahkan callback helper setelah flow OIDC stabil.
- Tambahkan Rack/Rails middleware hanya jika minimal dua app membutuhkan pola yang sama.

Jangan menaruh provider logic accounts di sini. Package ini adalah client SDK, bukan identity provider.

### Tahap 6: Matangkan `packages/identity-ui`

Status: package ini sudah dibuat.

Langkah pematangan:

- Pindahkan auth view yang reusable ke `packages/identity-ui`.
- Pertahankan form contract dan route tetap dikuasai accounts.
- Pisahkan brand slot dari form security.
- Tambahkan fallback default brand view.
- Tambahkan system test untuk brand default dan minimal satu brand contoh.

## Strategi Compatibility Selama Migrasi

Selama transisi, `satu-raya-commons` boleh menjadi wrapper sementara.

Contoh:

```ruby
module SatuRayaCommons
  module Identity
    TokenVerifier = SatuRayaIdentity::TokenVerifier
  end
end
```

Tujuannya:

- App lama tidak langsung rusak.
- Perpindahan bisa per kelompok.
- Breaking change dapat dijadwalkan.

Aturan:

- Wrapper diberi deprecation note.
- Jangan biarkan wrapper hidup tanpa batas waktu.
- Set target penghapusan, misalnya setelah `identity` stabil dua release.

## Risiko Pemecahan Commons

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Refactor terlalu besar | Banyak app rusak bersamaan | Pindah per kelompok kecil |
| Autoload path berubah | Constant tidak ditemukan runtime | Tambahkan smoke test per app |
| Circular dependency | Package saling membutuhkan | Tetapkan arah dependency |
| Commons tetap membesar | Masalah lama tidak selesai | Tambahkan aturan ownership |
| Identity logic tersebar | Security review sulit | Identity domain hanya di `packages/identity` dan provider di `apps/accounts` |
| UI auth bocor ke package umum | Klien bisa override security behavior | Form security tetap di accounts/identity |

## Arah Dependency Yang Diizinkan

Target dependency:

```text
apps/accounts
-> packages/identity
-> packages/identity-ui
-> packages/identity-client
-> packages/system
-> packages/commons

apps/jobs/business/core/training
-> packages/identity-client
-> packages/commons

apps/jobs/business/core/training
-> packages/ui
-> packages/commons

packages/identity-ui
-> packages/identity-client
-> packages/ui
-> packages/commons
```

Yang harus dihindari:

```text
packages/commons -> packages/identity
packages/commons -> apps/accounts
packages/identity-client -> apps/accounts
packages/ui -> apps/accounts
packages/identity-ui -> apps/accounts
packages/identity -> business/jobs/payroll/training domain
apps/accounts -> packages/communication tanpa kebutuhan identity yang jelas
apps/accounts -> packages/core-domain tanpa kebutuhan identity yang jelas
```

## Rekomendasi Praktis Untuk Saat Ini

Untuk fase sekarang:

1. Jangan langsung memecah ulang semua package yang sudah ada.
2. Buat inventory `packages/commons` untuk memastikan hanya primitive netral yang tersisa.
3. Hentikan penambahan identity-specific code baru ke `commons`.
4. Jika ada identity domain code baru, taruh di `packages/identity`.
5. Jika ada client integration code baru, taruh di `packages/identity-client`.
6. Jika ada auth view atau brand slot baru, taruh di `packages/identity-ui`.
7. Jika ada komponen UI netral baru, taruh di `packages/ui`.
8. Pertahankan Dockerfile accounts dengan selective package copy.
9. Jalankan build/smoke test accounts setelah perubahan boundary package.

Keputusan penting:

```text
Docker image accounts tetap unit deploy utama.
packages/identity adalah reusable domain layer.
packages/identity-client adalah integration SDK.
packages/identity-ui adalah presentation layer identity.
packages/commons hanya untuk primitive netral.
```

## Checklist Kesiapan Produksi (Reusable)

Sebelum melakukan deployment brand baru, pastikan hal berikut sudah siap:

1. **Environment Variables**: Minimal set sesuai tabel di atas.
2. **Database Isolation**: Database baru untuk brand tersebut.
3. **SSO Client Configuration**: Daftarkan app yang akan menggunakan brand ini di tabel `sso_client_configurations`.
4. **Custom Views (Opsional)**: Jika butuh hero atau background unik, buat di `packages/identity-ui/app/views/brands/<brand_slug>/identity/`.
5. **SSL Certificate**: Sertifikat untuk domain baru.
6. **SMTP Credentials**: Gunakan sender email sesuai brand.

## Strategi Testing Multi-brand

Untuk memverifikasi bahwa image tetap reusable tanpa merusak brand lain:

1. **Local Compose Test**: Gunakan `infra/compose/docker-compose.brand-example.yml` untuk menjalankan dua instance accounts secara lokal dengan konfigurasi berbeda.
2. **Request Spec dengan Host**: Selalu gunakan `host!` dalam testing untuk mensimulasikan domain yang berbeda.
3. **OIDC Simulation**: Jalankan script skenario IAM yang mencakup simulasi token exchange.

---
*Dokumen ini diperbarui secara berkala sesuai perkembangan implementasi arsitektur Satu Raya Integrasi.*
