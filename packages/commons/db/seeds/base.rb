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
      
      puts "✅ Centralized Seeding Complete!"
    end

    private

    def create_tenants
      domain = SatuRayaIdentityClient::Identity::BrandConfig.app_domain
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

          # Employer
          ::Identity::User.find_or_create_by!(email: "employer@#{tenant.slug}.com") do |u|
            u.tenant = tenant
            u.password = "Password123!456"
            u.first_name = "Employer"
            u.last_name = tenant.name
            u.role = :employer
            u.verified = true
          end

          # Worker
          ::Identity::User.find_or_create_by!(email: "worker@#{tenant.slug}.com") do |u|
            u.tenant = tenant
            u.password = "Password123!456"
            u.first_name = "Worker"
            u.last_name = tenant.name
            u.role = :worker
            u.verified = true
          end
        end
      end
      puts "  - Created base users for all tenants"
    end
  end
end
