# Satu Raya Identity

`packages/identity` adalah target package untuk domain identity reusable di bawah umbrella Satu Raya Integrasi.

Package ini disiapkan sebagai boundary baru. Pada tahap awal, package ini **belum dipakai oleh aplikasi** dan belum menggantikan `satu-raya-commons`. Kode identity yang sudah ada tetap berjalan dari `packages/commons` sampai proses migrasi dilakukan bertahap.

## Purpose

Package ini nantinya menjadi tempat untuk:

- Identity models.
- Identity use cases.
- Identity repositories.
- Identity services.
- Session, MFA, token, passkey, consent, dan permission metadata.

Contoh target:

```text
Identity::User
Identity::Session
Identity::UserPermission
Identity::SsoClientConfiguration
UseCases::Identity::Login
UseCases::Identity::Register
UseCases::Identity::VerifyMfa
UseCases::Identity::RevokeSession
```

## Not A Provider App

Package ini bukan aplikasi login.

Provider tetap:

```text
apps/accounts
```

`apps/accounts` tetap memiliki:

- Login/register controller.
- Password reset controller.
- MFA challenge controller.
- OAuth/OIDC provider endpoints.
- Consent screen.
- Accounts views.
- Brand rendering.
- Identity mailers.

## Do Not Add

Jangan menambahkan hal berikut ke package ini:

- Domain jobs.
- Domain payroll.
- Domain attendance.
- Domain recruitment.
- Domain training.
- Brand-specific views.
- Accounts provider controllers.
- OIDC client integration untuk app lain.

Target untuk client integration adalah:

```text
packages/identity-client
```

Target untuk shared UI adalah:

```text
packages/ui
```

## Migration Plan

Migrasi dari `packages/commons` harus dilakukan kecil-kecil.

Urutan yang direkomendasikan:

1. Pindahkan utility kecil yang baru dan minim dependency.
2. Tambahkan wrapper compatibility di `satu-raya-commons` jika perlu.
3. Jalankan targeted accounts specs.
4. Jalankan smoke test app internal.
5. Baru pindahkan model/use case identity yang lebih besar.

Kandidat awal:

```text
packages/commons/lib/satu_raya_commons/identity/redirect_validator.rb
packages/commons/lib/satu_raya_commons/identity/brand_config.rb
```

Jangan memindahkan semua `Identity::*` sekaligus.
