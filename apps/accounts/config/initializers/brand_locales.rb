# frozen_string_literal: true

# Load brand-specific locale files if they exist.
# Expected path: config/locales/brands/<brand_slug>.<locale>.yml
brand_slug = SatuRayaIdentityClient::Identity::BrandConfig.slug
brand_locales_path = Rails.root.join("config", "locales", "brands", brand_slug)

if Dir.exist?(brand_locales_path)
  Rails.application.config.i18n.load_path += Dir[brand_locales_path.join("*.{rb,yml}")]
end
