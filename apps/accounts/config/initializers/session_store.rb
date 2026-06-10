# Be sure to restart your server when you modify this file.

require "satu_raya_identity_client/identity/brand_config"

# Configure session store with brand-aware cookies to allow seamless single-sign-on
# across subdomains in the configured domain.
domain = SatuRayaIdentityClient::Identity::BrandConfig.app_domain
tld_length = ENV.fetch("SESSION_STORE_TLD_LENGTH", domain.split(".").size).to_i

Rails.application.config.session_store :cookie_store,
  key: SatuRayaIdentityClient::Identity::BrandConfig.session_cookie_name,
  domain: SatuRayaIdentityClient::Identity::BrandConfig.session_cookie_domain,
  tld_length: tld_length,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
