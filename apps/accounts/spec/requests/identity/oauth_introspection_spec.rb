# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC Token Introspection", type: :request do
  let!(:tenant) { create(:tenant, domain: "introspect.example.com") }
  let!(:user) { create(:user, tenant: tenant, role: :user, verified: true) }
  let!(:service_client) do
    Identity::ServiceClient.create!(
      tenant: tenant,
      service_name: "test-service",
      client_id: "test_service_client_id",
      secret: "super_secure_service_secret_123",
      allowed_scopes: [ "introspect", "user.sync" ],
      allowed_ips: [ "127.0.0.1" ],
      active: true
    )
  end

  let(:now) { Time.current.to_i }
  let(:access_token_payload) do
    {
      iss: "https://introspect.example.com",
      sub: user.id.to_s,
      tenant_id: tenant.id.to_s,
      aud: "sso_client_id",
      exp: 1.hour.from_now.to_i,
      iat: now,
      scopes: "openid profile email"
    }
  end
  let(:valid_token) { JWT.encode(access_token_payload, Rails.application.secret_key_base, "HS256") }

  before do
    host! "introspect.example.com"
    Rails.cache.clear
  end

  describe "POST /oauth/introspect" do
    context "with valid client credentials (Basic Auth)" do
      let(:auth_header) do
        { "Authorization" => "Basic " + Base64.encode64("test_service_client_id:super_secure_service_secret_123").strip }
      end

      it "returns active: true and user metadata for a valid token" do
        post oauth_introspect_path, params: { token: valid_token }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["active"]).to be true
        expect(json["user_id"]).to eq(user.id.to_s)
        expect(json["tenant_id"]).to eq(tenant.id.to_s)
        expect(json["role"]).to eq("user")
        expect(json["permissions"]).to be_an(Array)
      end

      it "returns active: false for an expired token" do
        expired_payload = access_token_payload.merge(exp: 10.minutes.ago.to_i)
        expired_token = JWT.encode(expired_payload, Rails.application.secret_key_base, "HS256")

        post oauth_introspect_path, params: { token: expired_token }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["active"]).to be false
      end

      it "returns active: false for an invalid or malformed token" do
        post oauth_introspect_path, params: { token: "malformed.jwt.token" }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["active"]).to be false
      end

      it "returns active: false if the user is inactive" do
        user.update!(active: false)

        post oauth_introspect_path, params: { token: valid_token }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["active"]).to be false
      end

      it "returns 400 Bad Request if the tenant is inactive (tenant not resolved)" do
        tenant.update!(active: false)

        post oauth_introspect_path, params: { token: valid_token }, headers: auth_header

        expect(response).to have_http_status(:bad_request)
      end

      it "returns active: false if the token's tenant_id does not match the user's tenant_id" do
        other_tenant = create(:tenant, domain: "other.example.com")
        mismatch_payload = access_token_payload.merge(tenant_id: other_tenant.id.to_s)
        mismatch_token = JWT.encode(mismatch_payload, Rails.application.secret_key_base, "HS256")

        post oauth_introspect_path, params: { token: mismatch_token }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["active"]).to be false
      end
    end

    context "with valid client credentials (POST parameters)" do
      it "authenticates successfully and returns active status" do
        post oauth_introspect_path, params: {
          client_id: "test_service_client_id",
          client_secret: "super_secure_service_secret_123",
          token: valid_token
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["active"]).to be true
      end
    end

    context "with invalid client credentials" do
      let(:invalid_auth_header) do
        { "Authorization" => "Basic " + Base64.encode64("test_service_client_id:wrong_secret").strip }
      end

      it "returns unauthorized error" do
        post oauth_introspect_path, params: { token: valid_token }, headers: invalid_auth_header

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("invalid_client")
      end
    end

    context "with inactive service client" do
      before { service_client.update!(active: false) }
      let(:auth_header) do
        { "Authorization" => "Basic " + Base64.encode64("test_service_client_id:super_secure_service_secret_123").strip }
      end

      it "returns unauthorized error" do
        post oauth_introspect_path, params: { token: valid_token }, headers: auth_header

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with missing token parameter" do
      let(:auth_header) do
        { "Authorization" => "Basic " + Base64.encode64("test_service_client_id:super_secure_service_secret_123").strip }
      end

      it "returns bad request error" do
        post oauth_introspect_path, params: {}, headers: auth_header

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("missing_token")
      end
    end

    context "with service client missing introspect scope" do
      before { service_client.update!(allowed_scopes: ["user.sync"]) }
      let(:auth_header) do
        { "Authorization" => "Basic " + Base64.encode64("test_service_client_id:super_secure_service_secret_123").strip }
      end

      it "returns forbidden error" do
        post oauth_introspect_path, params: { token: valid_token }, headers: auth_header

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("forbidden")
      end
    end
  end
end
