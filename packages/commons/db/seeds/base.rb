# Centralized helper for seeding across Satu Raya monorepo

module SatuRayaCommons
  class Seeder
    def self.run
      new.run
    end

    def run
      # Disable Searchkick callbacks during seeding if available
      Searchkick.disable_callbacks if defined?(Searchkick)

      puts "🌱 Starting Centralized Seeding..."
      
      create_tenants
      create_base_users
      create_client_configurations
      
      puts "✅ Centralized Seeding Complete!"
    end

    private

    def create_tenants
      domain = SatuRayaCommons::Config.app_domain
      @tenants = [
        System::Tenant.find_or_create_by!(slug: "demo") do |t|
          t.name   = "Demo Company"
          t.plan   = "starter"
          t.active = true
          t.domain = "demo.#{domain}"
        end,
        System::Tenant.find_or_create_by!(slug: "techcorp") do |t|
          t.name   = "TechCorp Indonesia"
          t.plan   = "pro"
          t.active = true
          t.domain = "techcorp.#{domain}"
        end
      ]
      puts "  - Created #{@tenants.size} tenants"
    end

    def create_base_users
      @tenants.each do |tenant|
        ActsAsTenant.with_tenant(tenant) do
          # Admin
          ::Identity::User.find_or_create_by!(email: "admin@#{tenant.slug}.com") do |u|
            u.tenant = tenant
            u.password = "Password123!456"
            u.first_name = "Admin"
            u.last_name = tenant.name
            u.role = :admin
            u.verified = true
          end

          # Support
          ::Identity::User.find_or_create_by!(email: "support@#{tenant.slug}.com") do |u|
            u.tenant = tenant
            u.password = "Password123!456"
            u.first_name = "Support"
            u.last_name = tenant.name
            u.role = :support
            u.verified = true
          end

          # Regular User
          ::Identity::User.find_or_create_by!(email: "user@#{tenant.slug}.com") do |u|
            u.tenant = tenant
            u.password = "Password123!456"
            u.first_name = "User"
            u.last_name = tenant.name
            u.role = :user
            u.verified = true
          end
        end
      end
      puts "  - Created base users for all tenants"
    end

    def create_client_configurations
      @tenants.each do |tenant|
        ActsAsTenant.with_tenant(tenant) do
          # SSO Client Configuration
          ::Identity::SsoClientConfiguration.find_or_create_by!(client_id: "sso_client_#{tenant.slug}") do |c|
            c.tenant = tenant
            c.client_name = "Demo SSO Client - #{tenant.name}"
            c.client_secret = "secret_sso_client_#{tenant.slug}"
            c.redirect_uris = ["http://localhost:3000/auth/callback", "https://oauth.pstmn.io/v1/callback"]
            c.allowed_scopes = ["openid", "profile", "email"]
            c.active = true
          end

          # Service Client Configuration (M2M Introspection)
          ::Identity::ServiceClient.find_or_create_by!(client_id: "service_client_#{tenant.slug}") do |s|
            s.tenant = tenant
            s.service_name = "jobs-service-#{tenant.slug}"
            s.secret = "secret_service_client_#{tenant.slug}"
            s.allowed_scopes = ["introspect", "user.sync"]
            s.allowed_ips = ["127.0.0.1", "0.0.0.0"]
            s.active = true
          end

          # External API Client
          ::Identity::ApiClient.find_or_create_by!(api_key: "api_key_#{tenant.slug}") do |a|
            a.tenant = tenant
            a.name = "API Client - #{tenant.name}"
            a.api_secret = "secret_api_client_#{tenant.slug}"
            a.rate_limit_per_minute = 60
            a.allowed_ips = ["127.0.0.1", "0.0.0.0"]
            a.active = true
          end
        end
      end
      puts "  - Created default client configurations (SSO, M2M, API)"
    end
  end
end
