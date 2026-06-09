module SatuRayaIdentityUi
  module BrandViewHelper
    # Mengembalikan nama brand dari konfigurasi.
    # @return [String]
    def brand_name
      SatuRayaCommons::Config.brand_name
    end

    # Mengembalikan URL logo brand.
    # @return [String, nil]
    def brand_logo_url
      SatuRayaCommons::Config.brand_logo_url
    end

    # Mengembalikan warna primer brand.
    # @return [String]
    def brand_primary_color
      SatuRayaCommons::Config.brand_primary_color
    end

    # Mengembalikan URL kebijakan privasi.
    # @return [String]
    def brand_privacy_url
      SatuRayaCommons::Config.brand_privacy_url
    end

    # Mengembalikan URL syarat dan ketentuan.
    # @return [String]
    def brand_terms_url
      SatuRayaCommons::Config.brand_terms_url
    end

    # Renders a brand-specific partial if it exists, otherwise falls back to the default brand partial.
    # @param name [String] The name of the partial (e.g., "identity/hero")
    # @param locals [Hash] Local variables to pass to the partial
    def render_brand_partial(name, locals = {})
      brand_slug = SatuRayaCommons::Config.brand_slug
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
