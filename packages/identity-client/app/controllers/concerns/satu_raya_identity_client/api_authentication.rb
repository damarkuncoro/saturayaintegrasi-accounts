module SatuRayaIdentityClient
  module ApiAuthentication
    extend ActiveSupport::Concern

    included do
      include SatuRayaCommons::ApiResponder
      include Pundit::Authorization

      set_current_tenant_through_filter
      before_action :set_current_request_details
      before_action :authenticate_api_user!

      after_action :verify_authorized, except: :index
      after_action :verify_policy_scoped, only: :index
    end

    def current_user
      System::Current.user
    end

    private

    def authenticate_api_user!
      token = request.headers["Authorization"]&.split(" ")&.last
      if token.blank?
        render_unauthorized("Missing Authorization header")
        return
      end

      # Decode token using configured secret and algorithm
      config = SatuRayaIdentityClient.configuration || SatuRayaIdentityClient::Configuration.new
      begin
        payload, _header = JWT.decode(token, config.jwt_secret, true, { algorithm: config.jwt_algorithm })

        # Set Current user with data from token
        # This makes it independent of a local User model
        user_data = payload.with_indifferent_access

        # If the app has an Identity::User model, we can try to find it
        user = if defined?(::Identity::User)
          ::Identity::User.find_by(id: user_data[:sub] || user_data[:user_id])
        end

        # Fallback to a Hashie::Mash or OpenStruct-like object if no local user model
        System::Current.user = user || Struct.new(*user_data.keys.map(&:to_sym)).new(*user_data.values)

        # Handle tenancy if present in token
        tenant_id = user_data[:tenant_id] || user_data[:tid]
        if tenant_id && defined?(::System::Tenant)
          tenant = ::System::Tenant.find_by(id: tenant_id)
          System::Current.tenant = tenant
          ActsAsTenant.current_tenant = tenant if defined?(ActsAsTenant)
        end
      rescue JWT::DecodeError => e
        log_authentication_failure(e)
        render_unauthorized("Invalid or expired token")
      rescue StandardError => e
        log_authentication_failure(e)
        render_unauthorized("Authentication failed")
      end
    end

    def set_current_request_details
      System::Current.user_agent = request.user_agent
      System::Current.ip_address = request.ip
    end

    def log_authentication_failure(exception)
      Rails.logger.warn(
        "[SatuRayaIdentityClient::ApiAuthentication] #{exception.class}: #{exception.message}"
      )
    end
  end
end

# Alias for backward compatibility
module SatuRayaCommons
  ApiAuthentication = SatuRayaIdentityClient::ApiAuthentication
end
