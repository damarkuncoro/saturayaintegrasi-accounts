# Satu Raya Accounts (IAM)

Layanan Identity and Access Management (IAM) terpusat untuk ekosistem Satu Raya.

## 📖 Dokumentasi

Seluruh dokumentasi teknis, arsitektur, dan panduan penggunaan tersedia di folder [docs/](docs/):

- **[Pusat Dokumentasi](docs/README.md)**
- **[Fitur & Panduan Penggunaan](docs/accounts/FEATURES.md)**
- **[Arsitektur Sistem](docs/accounts/ARCHITECTURE.md)**
- **[Setup Pengembangan Lokal](apps/accounts/README.md)**

## 🚀 Quick Start

Untuk menjalankan seluruh stack (Database, Redis, Proxy, App) menggunakan Docker Compose:

```bash
cd infra/compose
docker compose up -d
./trust-ssl.sh
```

Akses aplikasi di: [https://accounts.satu-raya.dev](https://accounts.satu-raya.dev)

## 📂 Struktur Project

Repositori ini menggunakan struktur **Monorepo (Modular Monolith)**:

- `apps/`: Aplikasi utama (Rails).
- `packages/`: Package internal (Gems) yang membagi logika bisnis (Auth, UI, System).
- `infra/`: Konfigurasi infrastruktur (Docker, Caddy, Proxy).
- `docs/`: Dokumentasi lengkap.
