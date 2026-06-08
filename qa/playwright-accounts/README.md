# Playwright Accounts Tests

Direktori ini berisi pengujian otomatis untuk layanan **Satu Raya Accounts (IAM)** menggunakan Playwright.

## Struktur Direktori
- `tests/auth/`: Skenario login, registrasi, dan password reset.
- `tests/security/`: Skenario 2FA, challenge OTP, dan active sessions.
- `support/pages/`: Page objects untuk form dan halaman Accounts.
- `support/fixtures/`: Data uji statis.
- `support/utils/`: Helper untuk OTP, Docker/Rails runner, dan data dinamis.
- `playwright.config.ts`: Konfigurasi utama Playwright untuk proyek ini.

## Cara Menjalankan Tes

Pastikan layanan Docker sudah berjalan (`docker compose up -d`).

Jalankan semua tes dari root direktori:
```bash
npm run test:accounts
```

Jalankan test tertentu:
```bash
bin/test-accounts qa/playwright-accounts/tests/auth/login.spec.ts
```

Atau jalankan dengan UI mode:
```bash
bin/test-accounts --ui
```

## Prasyarat Lokal

- Docker Compose stack di `infra/compose/` sudah aktif.
- Hostname berikut resolve ke `127.0.0.1`:
  - `accounts.satu-raya.dev`
  - `jobs.satu-raya.dev`
  - `business.satu-raya.dev`
- Local TLS/Caddy boleh menggunakan self-signed certificate; konfigurasi Playwright memakai `ignoreHTTPSErrors: true`.

## Fitur yang Diuji
- [x] Login dengan kredensial valid (Admin)
- [x] Validasi pesan error untuk kredensial tidak valid
- [x] Logout dan redirect kembali ke login
- [x] Registrasi Worker dan Employer
- [x] Password reset request dan complete reset loop
- [x] 2FA enable/disable lifecycle
- [x] 2FA challenge saat login
- [x] Active sessions dan revoke session
- [x] Validasi Single Sign-On (SSO) dan cookie lintas subdomain melalui flow Accounts

## Artefak

Setiap run dapat menghasilkan:

- `playwright-report/`: HTML report.
- `test-results/`: trace, video, dan screenshot.

Artefak ini bersifat sementara dan aman dihapus setelah hasil test sudah ditinjau.
