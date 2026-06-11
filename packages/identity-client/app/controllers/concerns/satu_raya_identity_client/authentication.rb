module SatuRayaIdentityClient
  module Authentication
    extend ActiveSupport::Concern
    include SatuRayaNavigation::NavigationHelpers

    included do
      before_action :require_authentication
      helper_method :authenticated_dashboard_path
    end

    class_methods do
      def allow_unauthenticated_access(**options)
        skip_before_action :require_authentication, **options
      end
    end

    def authenticated_dashboard_path
      identity_dashboard_url
    end

    private

    def require_authentication
      authenticated? || request_authentication
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      config = SatuRayaIdentityClient.configuration || SatuRayaIdentityClient::Configuration.new
      
      # Prefer configured accounts_url, fallback to helper
      login_url = if config.accounts_url.present?
                    "#{config.accounts_url}/login"
                  else
                    accounts_url_for("/login")
                  end
                  
      redirect_to login_url, allow_other_host: true
    end

    def after_authentication_url
      SatuRayaIdentityClient::Identity::RedirectValidator.safe_url(
        session.delete(:return_to_after_authenticating),
        fallback: authenticated_dashboard_path
      )
    end

    def redirect_if_authenticated
      if authenticated?
        redirect_to authenticated_dashboard_path, allow_other_host: true
      end
    end

    def start_new_session_for(user)
      if user.respond_to?(:sessions)
        user.sessions.create!(
          tenant: (user.respond_to?(:tenant) ? user.tenant : nil) || (defined?(System::Current) ? System::Current.tenant : nil),
          user_agent: request.user_agent,
          ip_address: request.ip
        ).tap do |session|
          System::Current.session = session if defined?(System::Current)
          cookies.signed.permanent[auth_session_cookie_name] = session_cookie_options(session.id)
        end
      else
        raise NotImplementedError, "start_new_session_for is only supported on identity providers"
      end
    end

    def terminate_session
      if defined?(System::Current) && System::Current.session
        if defined?(::UseCases::Identity::Auth::RevokeSession) && !System::Current.session.revoked?
          ::UseCases::Identity::Auth::RevokeSession.new.execute(
            session: System::Current.session,
            reason: "user_logout"
          )
        end
      end
      cookies.delete(auth_session_cookie_name, domain: session_cookie_domain)
    end

    def session_cookie_options(value)
      secure_val = defined?(Rails) && Rails.respond_to?(:env) && Rails.env.production?
      { value: value, httponly: true, secure: secure_val, same_site: :lax, domain: session_cookie_domain }
    end

    def auth_session_cookie_name
      brand_config.auth_session_cookie_name
    end

    def trusted_device_cookie_name
      brand_config.trusted_device_cookie_name
    end

    def session_cookie_domain
      brand_config.session_cookie_domain
    end
  end
end
