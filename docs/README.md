# Satu Raya Accounts Documentation Hub

Selamat datang di pusat dokumentasi layanan **Satu Raya Accounts (IAM)**. Repository ini berfokus pada penyediaan layanan manajemen identitas, otentikasi, dan otorisasi terpusat (Identity and Access Management) untuk seluruh ekosistem Satu Raya.

## 🚀 Getting Started

Untuk memulai pengembangan lokal, silakan pelajari panduan penyiapan service Accounts:

- **Setup & Panduan Kerja**: [Panduan Lengkap apps/accounts](../apps/accounts/README.md) — Menjelaskan tech stack, ERD database, setup local development, testing, seeding data, dan endpoint API utama.
- **Fitur & Penggunaan**: [Fitur & Panduan Penggunaan Accounts](accounts/FEATURES.md) — Daftar lengkap fitur IAM (2FA, Audit, SSO, Webhooks) dan cara menggunakannya.

## 🏗 Arsitektur & Spesifikasi IAM (Accounts Architecture)

Dokumentasi arsitektur teknis yang menjelaskan bagaimana sistem IAM beroperasi secara internal maupun berinteraksi dengan service lainnya:

- [Arsitektur Sistem (Overview)](accounts/ARCHITECTURE.md) — Penjelasan mengenai strategi Single Sign-On (SSO) lintas subdomain, resolusi multi-tenancy, dan siklus hidup user.
- [Kontrak API & Otorisasi](accounts/API-CONTRACT.md) — Detail spesifikasi pertukaran data (boundary contract), skema tabel `service_clients` internal, dan token introspection endpoint.
- [Kontrak Event Asinkron](accounts/EVENT-CONTRACT.md) — Spesifikasi payload event-driven identity sync, katalog event, dan verifikasi integritas menggunakan signature HMAC-SHA256.
- [Spesifikasi Keamanan](accounts/SECURITY.md) — Protokol pengamanan sistem, checklist keamanan wajib (MFA, rate limit, CORS, open redirect safeguard), dan arsitektur Refresh Token Rotation (RTR).
- [Roadmap Implementasi](accounts/ROADMAP.md) — Garis waktu pengembangan fungsionalitas Accounts dalam 4 fase utama.

## 📦 Distribusi & Reusability (Docker Packaging)

Informasi mengenai bagaimana service Accounts dibangun untuk dapat digunakan kembali (reusable) bagi berbagai penyewa/brand dengan satu basis kode yang sama:

- [Reusable Docker Image Guide](architecture/reusable-accounts-docker-image.md) — Panduan runbook docker multi-stage build, minimal environment variables untuk kustomisasi brand, isolasi database, boundary dependency package internal, dan tingkat kustomisasi tampilan (views customization).

## 📂 Pustaka & Paket Internal (Workspace Packages)

Workspace ini berisi beberapa gem internal (packages) yang membagi fungsionalitas dan logika agar tetap termodulasi dengan baik:

- [packages/commons](../packages/commons/README.md) — Primitif netral dan utilitas bersama lintas aplikasi.
- [packages/system](../packages/system/README.md) — Logika platform/system non-identity (seperti audit logging, webhook dispatching, dll).
- [packages/identity](../packages/identity/README.md) — Logika inti domain identity yang bersifat reusable.
- [packages/identity-client](../packages/identity-client/README.md) — SDK integrasi otentikasi untuk aplikasi klien yang ingin berintegrasi dengan Accounts.
- [packages/identity-ui](../packages/identity-ui/README.md) — Halaman presentasi visual identity reusable (views & helpers).
- [packages/navigation](../packages/navigation/README.md) — Helper URL dinamis dan navigasi lintas service sadar brand.
- [packages/ui](../packages/ui/README.md) — Komponen UI bersama (shared) non-otentikasi.

---
*Gunakan `bin/sk docs` untuk membuka dokumentasi ini di browser lokal Anda.*
