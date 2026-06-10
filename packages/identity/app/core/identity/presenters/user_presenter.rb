# frozen_string_literal: true

module Identity
  module Presenters
    class UserPresenter < ::Core::BasePresenter
      def as_json(_options = {})
        {
          sub: object.id.to_s,
          email: object.email,
          name: object.full_name,
          preferred_username: object.username,
          given_name: object.first_name,
          family_name: object.last_name,
          email_verified: object.email_verified?,
          role: object.role,
          tenant_id: object.tenant_id.to_s,
          created_at: object.created_at.iso8601
        }
      end

      def oidc_userinfo
        {
          sub: object.id.to_s,
          email: object.email,
          name: object.full_name,
          preferred_username: object.username,
          given_name: object.first_name,
          family_name: object.last_name,
          email_verified: object.email_verified?
        }
      end
    end
  end
end
