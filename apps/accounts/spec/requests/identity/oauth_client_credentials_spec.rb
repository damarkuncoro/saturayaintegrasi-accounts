# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC / OAuth2 Client Credentials Grant (M2M)", type: :request do
  let!(:tenant) { create(:tenant, domain: "oauth.example.com") }
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

  before do
    host! "oauth.example.com"
    Rails.cache.clear
  end

  describe "POST /oauth/token (grant_type=client_credentials)" do
    context "with valid client credentials (Basic Auth)" do
      let(:auth_header) do
        { "Authorization" => "Basic " + Base64.encode64("test_service_client_id:super_secure_service_secret_123").strip }
      end

      it "returns a valid M2M access token without id_token or refresh_token" do
        post oauth_token_path, params: {
          grant_type: "client_credentials"
        }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
        expect(json["token_type"]).to eq("Bearer")
        expect(json["expires_in"]).to eq(900)
        expect(json["scope"]).to eq("introspect user.sync")
        expect(json["id_token"]).to be_nil
        expect(json["refresh_token"]).to be_nil

        # Verify JWT claims
        payload, header = JWT.decode(json["access_token"], nil, false)
        expect(header["alg"]).to eq("RS256")
        expect(payload["sub"]).to eq("test_service_client_id")
        expect(payload["tenant_id"]).to eq(tenant.id.to_s)
        expect(payload["scopes"]).to eq("introspect user.sync")
        expect(payload["client_credentials"]).to be true
      end

      it "returns token for subset of allowed scopes if requested" do
        post oauth_token_path, params: {
          grant_type: "client_credentials",
          scope: "introspect"
        }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["scope"]).to eq("introspect")

        payload, _header = JWT.decode(json["access_token"], nil, false)
        expect(payload["scopes"]).to eq("introspect")
      end

      it "returns bad request if requesting an unallowed scope" do
        post oauth_token_path, params: {
          grant_type: "client_credentials",
          scope: "introspect write.all"
        }, headers: auth_header

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("invalid_scope")
      end
    end

    context "with invalid client credentials" do
      it "returns unauthorized error with basic auth" do
        auth_header = {
          "Authorization" => "Basic " + Base64.encode64("test_service_client_id:wrong_secret").strip
        }
        post oauth_token_path, params: { grant_type: "client_credentials" }, headers: auth_header

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("invalid_client")
      end

      it "returns unauthorized error with POST parameters" do
        post oauth_token_path, params: {
          grant_type: "client_credentials",
          client_id: "test_service_client_id",
          client_secret: "wrong_secret"
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /oauth/introspect of M2M token" do
    let!(:introspect_client) do
      Identity::ServiceClient.create!(
        tenant: tenant,
        service_name: "introspect-service",
        client_id: "introspect_client_id",
        secret: "introspect_secret_123",
        allowed_scopes: [ "introspect" ],
        allowed_ips: [ "127.0.0.1" ],
        active: true
      )
    end
    let(:auth_header) do
      { "Authorization" => "Basic " + Base64.encode64("introspect_client_id:introspect_secret_123").strip }
    end
    let(:token_payload) do
      {
        iss: "https://oauth.example.com",
        sub: service_client.client_id,
        tenant_id: tenant.id.to_s,
        aud: service_client.client_id,
        exp: 1.hour.from_now.to_i,
        iat: Time.current.to_i,
        scopes: "introspect",
        client_credentials: true
      }
    end
    let(:m2m_token) { JWT.encode(token_payload, Services::Identity::JwksManager.rsa_key, "RS256", { kid: Services::Identity::JwksManager.jwk[:kid] }) }

    it "returns active: true and client metadata for a valid M2M token" do
      post oauth_introspect_path, params: { token: m2m_token }, headers: auth_header

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["active"]).to be true
      expect(json["client_id"]).to eq(service_client.client_id)
      expect(json["tenant_id"]).to eq(tenant.id.to_s)
      expect(json["scopes"]).to eq("introspect")
      expect(json["user_id"]).to be_nil
    end

    it "returns active: false if the service client is inactive" do
      service_client.update!(active: false)

      post oauth_introspect_path, params: { token: m2m_token }, headers: auth_header

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["active"]).to be false
    end

    it "returns active: false if the token has expired" do
      expired_payload = token_payload.merge(exp: 10.minutes.ago.to_i)
      expired_token = JWT.encode(expired_payload, Services::Identity::JwksManager.rsa_key, "RS256", { kid: Services::Identity::JwksManager.jwk[:kid] })

      post oauth_introspect_path, params: { token: expired_token }, headers: auth_header

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["active"]).to be false
    end
  end
end
