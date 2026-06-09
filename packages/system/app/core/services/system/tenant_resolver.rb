# frozen_string_literal: true

module Services
  module System
    class TenantResolver
      attr_reader :request

      def initialize(request)
        @request = request
      end

      def resolve
        tenant = resolve_by_host
        tenant ||= resolve_by_subdomain
        tenant ||= resolve_by_header if Rails.env.development? || Rails.env.test?
        
        tenant if tenant&.active?
      end

      private

      def resolve_by_host
        host = normalize_host(request.host)
        return nil if host.blank?

        # 1. Match exact domain
        tenant = ::System::Tenant.active.find_by("lower(domain) = ?", host)
        return tenant if tenant

        # 2. Match brand config (accounts host mapping to default tenant)
        if host == normalize_host(accounts_host)
          return ::System::Tenant.active.find_by("lower(domain) = ?", normalize_host(app_domain))
        end

        nil
      end

      def resolve_by_subdomain
        # Example: tenant-slug.satu-raya.id
        subdomain = request.subdomains.first
        return nil if subdomain.blank? || reserved_subdomains.include?(subdomain)

        ::System::Tenant.active.find_by("lower(slug) = ?", subdomain.downcase)
      end

      def resolve_by_header
        # Useful for API testing/development
        tenant_id = request.headers["X-Tenant-ID"]
        return nil if tenant_id.blank?

        ::System::Tenant.active.find_by(id: tenant_id)
      rescue ActiveRecord::StatementInvalid
        nil
      end

      def normalize_host(host)
        host.to_s.strip.downcase.presence
      end

      def accounts_host
        if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
          SatuRayaIdentityClient::Identity::BrandConfig.accounts_host
        else
          ENV.fetch("APP_HOST", "accounts.satu-raya.dev")
        end
      end

      def app_domain
        if defined?(SatuRayaIdentityClient::Identity::BrandConfig)
          SatuRayaIdentityClient::Identity::BrandConfig.app_domain
        else
          ENV.fetch("APP_DOMAIN", "satu-raya.dev")
        end
      end

      def reserved_subdomains
        %w[www api admin accounts app assets static]
      end
    end
  end
end
