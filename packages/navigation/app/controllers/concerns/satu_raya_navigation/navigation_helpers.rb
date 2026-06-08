module SatuRayaNavigation
  module NavigationHelpers
    extend ActiveSupport::Concern

    included do
      helper_method :accounts_url_for, :jobs_url_for, :business_portal_url, :standardization_url_for, :identity_dashboard_url
    end

    # Helper to generate URL for accounts subdomain
    def accounts_url_for(path)
      domain = base_domain
      if request.host.include?(domain)
        "#{request.protocol}#{brand_config.accounts_host}#{request.port_string}#{path}"
      else
        path
      end
    end

    # Helper to generate URL for jobs subdomain
    def jobs_url_for(path)
      domain = base_domain
      if request.host.include?(domain)
        "#{request.protocol}#{brand_config.jobs_host}#{request.port_string}#{path}"
      else
        path
      end
    end

    # Helper to generate URL for business subdomain
    def business_portal_url(path_or_key)
      domain = base_domain
      path = path_or_key.is_a?(Symbol) ? "/#{path_or_key.to_s.gsub('_', '/')}" : path_or_key
      if request.host.include?(domain)
        "#{request.protocol}#{brand_config.business_host}#{request.port_string}#{path}"
      else
        path
      end
    end

    # Helper to generate URL for standardization subdomain
    def standardization_url_for(path)
      domain = base_domain
      if request.host.include?(domain)
        "#{request.protocol}#{brand_config.standardization_host}#{request.port_string}#{path}"
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
