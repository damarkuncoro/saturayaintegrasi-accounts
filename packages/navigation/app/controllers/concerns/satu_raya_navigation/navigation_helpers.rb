module SatuRayaNavigation
  module NavigationHelpers
    extend ActiveSupport::Concern

    included do
      helper_method :accounts_url_for, :identity_dashboard_url
    end

    # Helper to generate URL for accounts subdomain
    def accounts_url_for(path)
      subdomain = SatuRayaIdentityClient::Identity::BrandConfig.accounts_subdomain
      
      host = if request.host.start_with?("#{subdomain}.")
               request.host
             elsif defined?(System::Current) && System::Current.tenant&.domain.present?
               "#{subdomain}.#{System::Current.tenant.domain}"
             else
               SatuRayaCommons::Config.accounts_host
             end

      port_suffix = request.port == 80 || request.port == 443 ? "" : ":#{request.port}"
      "#{request.protocol}#{host}#{port_suffix}#{path}"
    end

    def identity_dashboard_url
      accounts_url_for("/dashboard")
    end

    private

    def base_domain
      SatuRayaCommons::Config.app_domain
    end
  end
end
