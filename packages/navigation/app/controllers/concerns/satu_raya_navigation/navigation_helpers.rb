module SatuRayaNavigation
  module NavigationHelpers
    extend ActiveSupport::Concern

    included do
      helper_method :accounts_url_for, :identity_dashboard_url
    end

    # Helper to generate URL for accounts subdomain
    def accounts_url_for(path)
      domain = base_domain
      if request.host.include?(domain)
        port_suffix = request.port == 80 || request.port == 443 ? "" : ":#{request.port}"
        "#{request.protocol}#{brand_config.accounts_host}#{port_suffix}#{path}"
      else
        path
      end
    end

    def identity_dashboard_url
      accounts_url_for("/dashboard")
    end

    private

    def base_domain
      brand_config.app_domain
    end

    def brand_config
      SatuRayaIdentityClient::Identity::BrandConfig
    end
  end
end
