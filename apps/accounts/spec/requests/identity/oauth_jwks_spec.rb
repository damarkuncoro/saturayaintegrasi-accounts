# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC / OAuth2 Asymmetric RS256 Signing & JWKS", type: :request do
  let!(:tenant) { create(:tenant, domain: "oauth.example.com") }
  let!(:user) { create(:user, tenant: tenant, verified: true) }
  let!(:sso_client) do
    create(
      :sso_client_configuration,
      tenant: tenant,
      client_secret: "supersecret",
      redirect_uris: [ "https://client.example.com/callback" ]
    )
  end
  let!(:service_client) do
    Identity::ServiceClient.create!(
      tenant: tenant,
      service_name: "test-service",
      client_id: "test_service_client_id",
      secret: "super_secure_service_secret_123",
      allowed_scopes: [ "introspect" ],
      allowed_ips: [ "127.0.0.1" ],
      active: true
    )
  end

  before do
    host! "oauth.example.com"
    Rails.cache.clear
  end

  describe "Discovery & JWKS" do
    it "advertises RS256 in openid-configuration" do
      get "/.well-known/openid-configuration"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["id_token_signing_alg_values_supported"]).to eq([ "RS256" ])
      expect(json["jwks_uri"]).to eq("#{json["issuer"]}/.well-known/jwks.json")
    end

    it "returns active public key parameters at jwks.json" do
      get "/.well-known/jwks.json"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["keys"]).to be_an(Array)
      expect(json["keys"].length).to eq(1)

      jwk = json["keys"].first
      expect(jwk["kty"]).to eq("RSA")
      expect(jwk["alg"]).to eq("RS256")
      expect(jwk["use"]).to eq("sig")
      expect(jwk["kid"]).to be_present
      expect(jwk["n"]).to be_present
      expect(jwk["e"]).to be_present
    end
  end

  describe "RS256 Token Issuance & Verification" do
    let(:auth_code) { SecureRandom.hex(16) }

    before do
      Rails.cache.write("oauth_code_#{auth_code}", {
        user_id: user.id,
        client_id: sso_client.client_id,
        scopes: "openid profile email",
        redirect_uri: "https://client.example.com/callback"
      }, expires_in: 5.minutes)
    end

    it "issues RS256 tokens and accepts them on Oauth endpoints" do
      client_auth = {
        "Authorization" => "Basic " + Base64.encode64("#{sso_client.client_id}:supersecret").strip
      }

      # Exchange authorization code for token
      post oauth_token_path, params: {
        grant_type: "authorization_code",
        code: auth_code,
        redirect_uri: "https://client.example.com/callback"
      }, headers: client_auth

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      access_token = json["access_token"]
      id_token = json["id_token"]

      # Decode tokens and inspect algorithm/headers
      _payload, access_header = JWT.decode(access_token, nil, false)
      _id_payload, id_header = JWT.decode(id_token, nil, false)

      expect(access_header["alg"]).to eq("RS256")
      expect(id_header["alg"]).to eq("RS256")

      # Fetch JWK and ensure kid matches
      get "/.well-known/jwks.json"
      jwk = JSON.parse(response.body)["keys"].first
      expect(access_header["kid"]).to eq(jwk["kid"])
      expect(id_header["kid"]).to eq(jwk["kid"])

      # Test UserInfo Endpoint accepts RS256
      get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{access_token}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["email"]).to eq(user.email)

      # Test Introspect Endpoint accepts RS256
      service_auth = {
        "Authorization" => "Basic " + Base64.encode64("test_service_client_id:super_secure_service_secret_123").strip
      }
      post oauth_introspect_path, params: { token: access_token }, headers: service_auth
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["active"]).to be true
    end
  end

  describe "Backward Compatibility for HS256 tokens" do
    let(:now) { Time.current.to_i }
    let(:legacy_access_token_payload) do
      {
        iss: "https://oauth.example.com",
        sub: user.id.to_s,
        tenant_id: tenant.id.to_s,
        aud: sso_client.client_id,
        exp: 1.hour.from_now.to_i,
        iat: now,
        scopes: "openid profile email"
      }
    end
    let(:legacy_token) { JWT.encode(legacy_access_token_payload, Rails.application.secret_key_base, "HS256") }

    it "accepts valid HS256 tokens on UserInfo and Introspection" do
      # Test legacy token on UserInfo
      get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{legacy_token}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["email"]).to eq(user.email)

      # Test legacy token on Introspect
      service_auth = {
        "Authorization" => "Basic " + Base64.encode64("test_service_client_id:super_secure_service_secret_123").strip
      }
      post oauth_introspect_path, params: { token: legacy_token }, headers: service_auth
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["active"]).to be true
    end
  end
end
