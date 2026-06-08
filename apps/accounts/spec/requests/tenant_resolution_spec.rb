require "rails_helper"

RSpec.describe "Tenant resolution", type: :request do
  describe "host-based tenant lookup" do
    it "resolves the accounts host to the configured app domain tenant" do
      tenant = create(:tenant, domain: SatuRayaIdentityClient::Identity::BrandConfig.app_domain)

      host! SatuRayaIdentityClient::Identity::BrandConfig.accounts_host

      post sign_up_path, params: {
        user: {
          email: "brand-user@example.com",
          password: "Secret1*3*5*",
          password_confirmation: "Secret1*3*5*",
          first_name: "Brand",
          last_name: "User",
          phone: "1234567890"
        }
      }

      expect(Identity::User.find_by(email: "brand-user@example.com").tenant).to eq(tenant)
    end

    it "does not fall back to the first tenant for unknown production hosts" do
      create(:tenant, domain: nil)

      allow(Rails.env).to receive(:production?).and_return(true)
      host! "unknown.example.com"

      get sign_in_path

      expect(response).to have_http_status(:bad_request)
    end
  end
end
