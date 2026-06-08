# Satu Raya Identity Client

`packages/identity-client` adalah target package untuk SDK integrasi aplikasi client dengan `apps/accounts`.

Package ini disiapkan sebagai boundary baru. Pada tahap awal, package ini **belum dipakai oleh aplikasi** dan belum menggantikan concern authentication yang masih berada di `packages/commons`.

## Purpose

Package ini nantinya membantu aplikasi lain memakai accounts sebagai identity provider.

Contoh aplikasi pemakai:

```text
apps/jobs
apps/business
apps/core
apps/training
produk/brand lain di luar Satu Raya
```

## Future Responsibilities

Yang cocok masuk package ini:

- Authorization URL builder.
- OIDC/OAuth callback helper.
- ID token verifier.
- Access token verifier.
- Userinfo client.
- Token refresh/revocation client.
- Rack/Rails middleware untuk protected route.
- Current user resolver berbasis token/session dari accounts.

Contoh target API:

```ruby
SatuRayaIdentityClient.configure do |config|
  config.issuer = ENV.fetch("ACCOUNTS_ISSUER")
  config.client_id = ENV.fetch("ACCOUNTS_CLIENT_ID")
  config.client_secret = ENV.fetch("ACCOUNTS_CLIENT_SECRET")
  config.redirect_uri = ENV.fetch("ACCOUNTS_REDIRECT_URI")
end
```

## Not Allowed

Jangan menambahkan hal berikut:

- Password verification flow.
- Session creation milik accounts.
- MFA challenge internal.
- Accounts login/register controllers.
- Accounts views.
- Database model penuh `Identity::User`.
- Brand-specific UI.
- Business domain logic.

Provider tetap:

```text
apps/accounts
```

Domain identity tetap:

```text
packages/identity
```

## Activation Rule

Jangan pasang package ini ke app Gemfile sebelum:

1. OIDC/accounts integration dipakai minimal dua app.
2. Kontrak issuer/client/redirect URI sudah stabil.
3. Token verifier dan callback flow sudah punya request specs.
4. Compatibility dengan `apps/accounts` terdokumentasi.
