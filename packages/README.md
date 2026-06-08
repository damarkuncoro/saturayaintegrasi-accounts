# Packages

Folder ini berisi package internal yang dipakai lintas aplikasi dalam monorepo Satu Raya Integrasi.

Satu Raya adalah produk turunan dari Satu Raya Integrasi. Karena itu, package baru sebaiknya dirancang sebagai bagian dari umbrella Satu Raya Integrasi, bukan hanya untuk Satu Raya.

Package boundary:

```text
packages/commons
packages/identity
packages/identity-client
packages/ui
```

Naming target jangka panjang:

```text
satu-raya-commons
satu-raya-identity
satu-raya-identity-client
satu-raya-ui
```

Naming saat ini masih memakai beberapa nama `satu-raya-*` demi kompatibilitas. Jangan rename package sebelum boundary arsitektur stabil.

Saat ini `packages/commons` sudah aktif dipakai aplikasi. `packages/identity`, `packages/identity-client`, dan `packages/ui` sudah disiapkan sebagai skeleton boundary, tetapi belum dipasang ke app Gemfile dan belum menggantikan kode yang masih berada di commons.

Jangan menambah domain baru ke `commons` tanpa mengecek ownership package di:

```text
docs/architecture/commons-package-inventory.md
docs/architecture/reusable-accounts-docker-image.md
```

## Ownership Rules

- `commons` hanya untuk primitive netral lintas aplikasi.
- `identity` akan menjadi tempat domain identity seperti user, session, MFA, token, consent, dan permission.
- `identity-client` akan menjadi SDK untuk aplikasi lain yang login via accounts/OIDC.
- `ui` akan menjadi tempat komponen visual shared yang tidak membawa auth logic.

## Do Not Add To Commons

Jangan menambah hal berikut ke `packages/commons`:

- Use case domain bisnis baru seperti attendance, payroll, recruitment, training, compliance, atau finance.
- View brand-specific.
- Controller/provider logic khusus accounts.
- Logic OIDC client sebelum ada package/client boundary.
- Model identity baru yang sulit dipindahkan ke `packages/identity`.

Jika ragu, tulis dulu di dokumen inventory dan pilih target package sebelum membuat kode.
