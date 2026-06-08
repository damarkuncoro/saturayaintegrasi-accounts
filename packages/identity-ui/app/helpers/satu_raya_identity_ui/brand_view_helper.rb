module SatuRayaIdentityUi
  module BrandViewHelper
    # Mengembalikan nama brand dari konfigurasi.
    # @return [String]
    def brand_name
      brand_config.name
    end

    # Mengembalikan URL logo brand.
    # @return [String, nil]
    def brand_logo_url
      brand_config.logo_url
    end

    # Mengembalikan warna primer brand.
    # @return [String]
    def brand_primary_color
      brand_config.primary_color
    end

    # Mengembalikan URL kebijakan privasi.
    # @return [String]
    def brand_privacy_url
      brand_config.privacy_url || "https://#{brand_config.app_domain}/privacy"
    end

    # Mengembalikan URL syarat dan ketentuan.
    # @return [String]
    def brand_terms_url
      brand_config.terms_url || "https://#{brand_config.app_domain}/terms"
    end

    # Renders a brand-specific partial if it exists, otherwise falls back to the default brand partial.
    # @param name [String] The name of the partial (e.g., "identity/hero")
    # @param locals [Hash] Local variables to pass to the partial
    def render_brand_partial(name, locals = {})
      brand_slug = brand_config.slug
      brand_path = "brands/#{brand_slug}/#{name}"
      default_path = "brands/default/#{name}"

      if lookup_context.exists?(brand_path, [], true)
        render partial: brand_path, locals: locals
      else
        render partial: default_path, locals: locals
      end
    end

    private

    def brand_config
      SatuRayaIdentityClient::Identity::BrandConfig
    end
  end
end
