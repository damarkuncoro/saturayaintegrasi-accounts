module System
  class Current < ActiveSupport::CurrentAttributes
    attribute :session
    attribute :tenant
    attribute :user
    attribute :user_agent, :ip_address
    attribute :request_id

    resets { Time.zone = nil }

    def user=(user)
      super
      # Auto-set tenant if user belongs to one and tenant not set
      self.tenant ||= user&.tenant if user.respond_to?(:tenant)
    end

    def tenant=(tenant)
      super
      ActsAsTenant.current_tenant = tenant
    end

    # For web, user is derived from session; for API, user is set directly
    def user
      super || session&.user
    end
  end
end
