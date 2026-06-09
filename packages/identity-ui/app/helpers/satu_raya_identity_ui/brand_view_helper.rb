module SatuRayaIdentityUi
  module BrandViewHelper
    # Mengembalikan nama brand dari konfigurasi.
    # @return [String]
    def brand_name
      if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
        SatuRayaIdentityClient::Identity::BrandConfig.name
      else
        ENV.fetch("BRAND_NAME", "Satu Raya")
      end
    end

    # Mengembalikan URL logo brand.
    # @return [String, nil]
    def brand_logo_url
      if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
        SatuRayaIdentityClient::Identity::BrandConfig.logo_url
      else
        ENV.fetch("BRAND_LOGO_URL", nil)
      end
    end

    # Mengembalikan warna primer brand.
    # @return [String]
    def brand_primary_color
      if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
        SatuRayaIdentityClient::Identity::BrandConfig.primary_color
      else
        ENV.fetch("BRAND_PRIMARY_COLOR", "#4f46e5")
      end
    end

    # Mengembalikan URL kebijakan privasi.
    # @return [String]
    def brand_privacy_url
      if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
        SatuRayaIdentityClient::Identity::BrandConfig.privacy_url || "https://#{SatuRayaIdentityClient::Identity::BrandConfig.app_domain}/privacy"
      else
        ENV.fetch("BRAND_PRIVACY_URL", "https://satu-raya.dev/privacy")
      end
    end

    # Mengembalikan URL syarat dan ketentuan.
    # @return [String]
    def brand_terms_url
      if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
        SatuRayaIdentityClient::Identity::BrandConfig.terms_url || "https://#{SatuRayaIdentityClient::Identity::BrandConfig.app_domain}/terms"
      else
        ENV.fetch("BRAND_TERMS_URL", "https://satu-raya.dev/terms")
      end
    end

    # Renders a brand-specific partial if it exists, otherwise falls back to the default brand partial.
    # @param name [String] The name of the partial (e.g., "identity/hero")
    # @param locals [Hash] Local variables to pass to the partial
    def render_brand_partial(name, locals = {})
      brand_slug = if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
                     SatuRayaIdentityClient::Identity::BrandConfig.slug
                   else
                     ENV.fetch("BRAND_SLUG", "satu-raya")
                   end
      brand_path = "brands/#{brand_slug}/#{name}"
      default_path = "brands/default/#{name}"

      if lookup_context.exists?(brand_path, [], true)
        render partial: brand_path, locals: locals
      else
        render partial: default_path, locals: locals
      end
    end
  end
end
