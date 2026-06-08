# Satu Raya UI

`packages/ui` adalah target package untuk komponen visual reusable yang netral terhadap produk/brand.

Package ini disiapkan sebagai boundary baru. Pada tahap awal, package ini **belum dipakai oleh aplikasi** dan belum menggantikan shared components yang masih berada di `packages/commons`.

## Purpose

Package ini nantinya menjadi tempat untuk UI primitive yang dipakai lintas aplikasi Satu Raya Integrasi.

Contoh:

```text
Button
Badge
Card
Flash
Form field
Form input
Empty state
Section header
Layout primitive
```

## Allowed

Kode boleh masuk package ini jika:

- Netral terhadap brand.
- Tidak membaca domain model secara langsung.
- Tidak membuat keputusan auth.
- Tidak membawa copywriting khusus produk.
- Bisa dipakai oleh accounts, jobs, business, training, dan produk lain.

## Not Allowed

Jangan menambahkan:

- Login/register flow.
- Password reset behavior.
- MFA challenge behavior.
- OIDC/OAuth callback behavior.
- Brand-specific hero.
- Logo/copy/color khusus Satu Raya atau klien tertentu.
- Komponen yang langsung membaca `System::Current` tanpa adapter.
- Domain bisnis jobs/payroll/attendance/training.

## Migration Candidates

Kandidat awal dari `packages/commons`:

```text
packages/commons/app/views/shared/components/_badge.html.erb
packages/commons/app/views/shared/components/_button.html.erb
packages/commons/app/views/shared/components/_card.html.erb
packages/commons/app/views/shared/components/_empty_state.html.erb
packages/commons/app/views/shared/components/_form_checkbox.html.erb
packages/commons/app/views/shared/components/_form_field.html.erb
packages/commons/app/views/shared/components/_form_input.html.erb
packages/commons/app/views/shared/components/_form_select.html.erb
packages/commons/app/views/shared/components/_section_header.html.erb
```

Jangan pindahkan navbar sebelum dependency ke `System::Current` dipisahkan.
