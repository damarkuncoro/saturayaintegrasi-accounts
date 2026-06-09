module SatuRayaIdentityClient
  module ControllerUtils
    extend ActiveSupport::Concern

    included do
      set_current_tenant_through_filter
      before_action :set_current_request_details
      before_action :resume_session
      before_action :assign_current_tenant
      
      helper_method :base_domain, :brand_config, :authenticated?, :current_user
    end

    def current_user
      System::Current.user
    end

    def authenticated?
      current_user.present?
    end

    # Helper to get base domain
    def base_domain
      @base_domain ||= brand_config.app_domain
    end

    def brand_config
      SatuRayaIdentityClient::Identity::BrandConfig
    end

    # Secure redirect_to to automatically allow subdomains
    def redirect_to(options = {}, response_options = {})
      if options.is_a?(String) && options.start_with?("http")
        begin
          uri = URI.parse(options)
          if SatuRayaIdentityClient::Identity::RedirectValidator.allowed_host?(uri.host)
            response_options[:allow_other_host] = true
          end
        rescue URI::InvalidURIError
          # Fallback
        end
      end
      super(options, response_options)
    end

    private

    def set_current_request_details
      System::Current.user_agent = request.user_agent
      System::Current.ip_address = request.ip
      System::Current.request_id = request.request_id
    end

    def resume_session
      if session = find_session_by_cookie
        System::Current.session = session
        if session.has_attribute?(:last_seen_at) && (session.last_seen_at.blank? || session.last_seen_at < 5.minutes.ago)
          session.update_columns(last_seen_at: Time.current)
        end
        session
      end
    end

    def find_session_by_cookie
      if defined?(::Identity::Session)
        ::Identity::Session.active.find_by(id: cookies.signed[brand_config.auth_session_cookie_name])
      end
    end

    def assign_current_tenant
      System::Current.tenant = tenant_from_request
    end

    def tenant_from_request
      # 1. Try resolving from request (host, subdomain, etc)
      tenant = if defined?(Services::System::TenantResolver)
                 Services::System::TenantResolver.new(request).resolve
               end
      
      # 2. Fallback to user's tenant if authenticated
      tenant ||= System::Current.user&.tenant if System::Current.user.respond_to?(:tenant)

      # 3. Development fallback
      if tenant.nil? && Rails.env.development? && defined?(::System::Tenant)
        tenant = ::System::Tenant.active.first
      end

      tenant
    end

    def user_not_authorized
      flash[:alert] = "Anda tidak memiliki akses ke halaman ini."
      redirect_back_or_to root_path
    end
  end
end
