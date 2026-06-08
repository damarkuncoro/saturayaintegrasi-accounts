# Satu Raya Commons

`packages/commons` adalah gem internal untuk primitive netral lintas aplikasi.

Nama gem saat ini masih `satu-raya-commons` untuk menjaga kompatibilitas. Secara arah produk, package ini adalah bagian dari umbrella Satu Raya Integrasi. Satu Raya adalah produk turunan, bukan batas akhir package.

Target naming jangka panjang:

```text
satu-raya-commons
```

Rename gem dilakukan belakangan setelah boundary package stabil.

Commons **bukan** tempat semua shared code. Jika kode hanya relevan untuk identity, UI, atau domain bisnis tertentu, kode tersebut sebaiknya tidak ditambahkan ke commons.

## Current Role

Untuk saat ini, commons masih berisi beberapa area yang akan dipisahkan bertahap:

- Shared security primitives.
- Shared controller concerns.
- Shared UI components.
- Identity domain.
- Business domain use cases.

Inventory lengkap ada di:

```text
docs/architecture/commons-package-inventory.md
```

## Allowed

Kode baru boleh masuk commons jika:

- Netral lintas semua aplikasi.
- Tidak spesifik accounts, jobs, business, training, payroll, atau attendance.
- Tidak membawa UI brand.
- Tidak mengikat aplikasi ke database service tertentu.
- Bisa digunakan tanpa mengetahui domain bisnis pemanggil.

Contoh yang cocok:

```text
SatuRayaCommons::Security::HmacSigner
SatuRayaCommons::Security::JwtCodec
SatuRayaCommons::ApiResponder
SatuRayaCommons::ErrorHandler
SatuRayaCommons::Cache
SatuRayaCommons::EventBus
SatuRayaCommons::Logging
```

## Avoid

Kode baru sebaiknya tidak masuk commons jika termasuk salah satu kategori ini:

- Identity domain baru.
- Accounts provider behavior.
- OIDC client integration.
- Shared UI component yang masih membaca `System::Current`.
- Attendance/payroll/recruitment/training/compliance/finance use case.
- Brand-specific view, copy, logo, color, atau mailer content.

Target package masa depan:

| Kode | Target |
| --- | --- |
| User, session, MFA, token, consent | `packages/identity` |
| Login client callback, token verifier, userinfo client | `packages/identity-client` |
| Button, form field, flash, card, layout primitive | `packages/ui` |
| Accounts login/register/OIDC provider UI | `apps/accounts` |
| Domain bisnis | App/package domain masing-masing |

## Migration Rule

Jangan memindahkan semua isi commons sekaligus.

Gunakan langkah kecil:

1. Tambahkan inventory.
2. Tentukan target package.
3. Pindahkan satu kelompok kecil.
4. Tambahkan wrapper compatibility jika perlu.
5. Jalankan spec/smoke test app yang terdampak.
6. Hapus wrapper setelah dua release stabil.
