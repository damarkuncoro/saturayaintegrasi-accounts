# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack Rate Limiting", type: :request do
  let!(:tenant) { create(:tenant, domain: "rate-limit.example.com") }

  before(:each) do
    host! "rate-limit.example.com"
    Rack::Attack.enabled = true
    @old_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end

  after(:each) do
    Rack::Attack.enabled = false
    Rack::Attack.cache.store = @old_store
  end

  describe "login attempts throttling" do
    it "throttles by email after 10 attempts" do
      email = "login-throttle@example.com"

      10.times do
        post sign_in_path, params: { email: email, password: "wrong_password" }
        expect(response.status).not_to eq(429)
      end

      post sign_in_path, params: { email: email, password: "wrong_password" }
      expect(response.status).to eq(429)

      json = JSON.parse(response.body)
      expect(json["error"]).to include("Rate limit exceeded")
    end
  end

  describe "registrations throttling" do
    it "throttles registrations by IP after 10 attempts" do
      10.times do
        post sign_up_path, params: { user: { email: "some@example.com" } }
        expect(response.status).not_to eq(429)
      end

      post sign_up_path, params: { user: { email: "some@example.com" } }
      expect(response.status).to eq(429)

      json = JSON.parse(response.body)
      expect(json["error"]).to include("Rate limit exceeded")
    end
  end

  describe "password resets throttling" do
    it "throttles password reset requests by IP after 10 attempts" do
      10.times do |i|
        post identity_password_reset_path, params: { email: "reset#{i}@example.com" }
        expect(response.status).not_to eq(429)
      end

      post identity_password_reset_path, params: { email: "reset10@example.com" }
      expect(response.status).to eq(429)

      json = JSON.parse(response.body)
      expect(json["error"]).to include("Rate limit exceeded")
    end

    it "throttles password reset requests by email after 5 attempts" do
      # Note: Since the IP limit is 10, the email limit (5) should trigger first.
      # To test this, we can vary the IP using a header or just make requests to the email.
      # Let's perform requests for the same email.
      email = "user-reset@example.com"

      5.times do
        post identity_password_reset_path, params: { email: email }
        expect(response.status).not_to eq(429)
      end

      post identity_password_reset_path, params: { email: email }
      expect(response.status).to eq(429)
    end
  end

  describe ".resolve_tenant_identifier" do
    it "resolves from X-Tenant-ID header" do
      req = double("Request", env: { "HTTP_X_TENANT_ID" => "tenant-uuid-123" })
      expect(Rack::Attack.resolve_tenant_identifier(req)).to eq("tenant-uuid-123")
    end

    it "resolves from JWT Bearer token" do
      user = create(:user, tenant: tenant)
      token = user.generate_jwt_token
      req = double("Request", env: { "HTTP_AUTHORIZATION" => "Bearer #{token}" })
      expect(Rack::Attack.resolve_tenant_identifier(req)).to eq(tenant.id)
    end

    it "resolves from subdomain" do
      req = double("Request", env: {}, host: "demo-tenant.satu-raya.dev")
      expect(Rack::Attack.resolve_tenant_identifier(req)).to eq("demo-tenant")
    end

    it "resolves from custom domain" do
      req = double("Request", env: {}, host: "mycustomdomain.com")
      expect(Rack::Attack.resolve_tenant_identifier(req)).to eq("mycustomdomain.com")
    end
  end

  describe "tenant-scoped throttles" do
    it "logins/tenant tracks by tenant identifier" do
      req = double("Request", path: "/login", post?: true, env: { "HTTP_X_TENANT_ID" => "tenant-123" })
      discriminator = Rack::Attack.throttles["logins/tenant"].block.call(req)
      expect(discriminator).to eq("tenant-123")
    end

    it "registrations/tenant tracks by tenant identifier" do
      req = double("Request", path: "/register", post?: true, env: { "HTTP_X_TENANT_ID" => "tenant-123" })
      discriminator = Rack::Attack.throttles["registrations/tenant"].block.call(req)
      expect(discriminator).to eq("tenant-123")
    end

    it "password_resets/tenant tracks by tenant identifier" do
      req = double("Request", path: "/identity/password_reset", post?: true, env: { "HTTP_X_TENANT_ID" => "tenant-123" })
      discriminator = Rack::Attack.throttles["password_resets/tenant"].block.call(req)
      expect(discriminator).to eq("tenant-123")
    end

    it "api/tenant tracks by tenant identifier" do
      req = double("Request", path: "/api/v1/users", env: { "HTTP_X_TENANT_ID" => "tenant-123" })
      discriminator = Rack::Attack.throttles["api/tenant"].block.call(req)
      expect(discriminator).to eq("tenant-123")
    end
  end
end
