# Satu Raya Documentation Hub

Selamat datang di pusat dokumentasi monorepo Satu Raya. Dokumen ini dirancang untuk membantu pengembang, PM, dan DevOps memahami arsitektur, standar, dan cara kerja ekosistem Satu Raya.

## 🚀 Getting Started

Jika Anda baru bergabung atau baru melakukan setup di mesin lokal, mulailah dari sini:

| Topik | Deskripsi |
| --- | --- |
| [Workspace Organization](development/workspace-organization.md) | Penjelasan struktur folder monorepo dan prinsip kerja. |
| [Developer Setup Guide](development/rails-implementation-guide.md) | Langkah-langkah instalasi dan menjalankan stack development. |
| [CLI bin/sk Guide](development/workspace-organization.md#tooling-terpadu) | Cara menggunakan alat bantu `bin/sk` untuk produktivitas. |
| [API Documentation Hub](api/index.html) | Portal Swagger/OpenAPI untuk seluruh layanan. |

## 🏗 Architecture & Standards

Memahami bagaimana Satu Raya dibangun dan bagaimana menjaga kualitas kode.

- **UI & Frontend**: [UI System Architecture](architecture/ui-system.md) (Contract/Base/Skin pattern).
- **Communication**: [Service Communication Map](architecture/service-map.md) (HMAC, Event Bus).
- **Standards**: [Unified API Response](architecture/api-responses.md) & [Error Codes](api/error-codes.md).
- **Testing**: [Commons Testing Guide](architecture/commons-testing.md) & [Definition of Done](development/definition-of-done.md).
- **Scaling**: [Scaling Roadmap](architecture/scaling.md) untuk pertumbuhan tinggi.

## 🛠 Technical Execution

- [Implementation Status](development/implementation-status.md) - Status nyata fitur saat ini.
- [Developer Implementation Backlog](development/developer-implementation-backlog.md) - Prioritas kerja teknis.
- [Engineering Implementation Guide](development/engineering-implementation-guide.md) - Best practices Ruby/Rails di Satu Raya.

## 💼 Product & Business

Dokumentasi mengenai strategi pilot, MVP, dan roadmap komersial.

- [Commercial MVP Scope](product/commercial-mvp.md)
- [Pilot Readiness Checklist](product/pilot-readiness-checklist.md)
- [Commercial Pricing Packages](product/commercial-pricing-packages.md)
- [Strategic Expansion Roadmap](product/strategic-expansion-roadmap.md)

## 📂 Archive & History

- [ADR (Architecture Decision Records)](adr/) - Sejarah keputusan arsitektur.
- [Legacy Documentation](archive/) - Briefing lama, laporan reorganisasi, dan sejarah schema.

---
*Gunakan `bin/sk docs` untuk membuka dokumentasi ini di browser lokal Anda.*
