module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      ActsAsTenant.current_tenant = current_user.tenant if current_user
      logger.add_tags "ActionCable", current_user.id
    end

    private

    def find_verified_user
      session_id = cookies.signed[SatuRayaIdentityClient::Identity::BrandConfig.auth_session_cookie_name]
      if session_id && session = Identity::Session.find_by(id: session_id)
        session.user
      else
        reject_unauthorized_connection
      end
    end
  end
end
