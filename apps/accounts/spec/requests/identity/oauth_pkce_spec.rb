# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC / OAuth2 PKCE (RFC 7636)", type: :request do
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

  before do
    host! "oauth.example.com"
    Rails.cache.clear
  end

  describe "Discovery Metadata" do
    it "advertises supported code challenge methods" do
      get "/.well-known/openid-configuration"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["code_challenge_methods_supported"]).to eq([ "plain", "S256" ])
    end
  end

  describe "Authorization Code Exchange with PKCE" do
    let(:client_auth) do
      {
        "Authorization" => "Basic " + Base64.encode64("#{sso_client.client_id}:supersecret").strip
      }
    end

    context "with S256 code challenge" do
      let(:code_verifier) { "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk" }
      # SHA256 of code_verifier, Base64URL-encoded without padding
      let(:code_challenge) { "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM" }
      let(:auth_code) { SecureRandom.hex(16) }

      before do
        Rails.cache.write("oauth_code_#{auth_code}", {
          user_id: user.id,
          client_id: sso_client.client_id,
          scopes: "openid profile email",
          redirect_uri: "https://client.example.com/callback",
          code_challenge: code_challenge,
          code_challenge_method: "S256"
        }, expires_in: 5.minutes)
      end

      it "succeeds when a valid code_verifier is provided" do
        post oauth_token_path, params: {
          grant_type: "authorization_code",
          code: auth_code,
          redirect_uri: "https://client.example.com/callback",
          code_verifier: code_verifier
        }, headers: client_auth

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
        expect(json["id_token"]).to be_present
      end

      it "fails with bad_request when code_verifier is incorrect" do
        post oauth_token_path, params: {
          grant_type: "authorization_code",
          code: auth_code,
          redirect_uri: "https://client.example.com/callback",
          code_verifier: "wrong_verifier"
        }, headers: client_auth

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("invalid_grant")
        expect(json["error_description"]).to eq("PKCE verification failed")
      end

      it "fails with bad_request when code_verifier is missing" do
        post oauth_token_path, params: {
          grant_type: "authorization_code",
          code: auth_code,
          redirect_uri: "https://client.example.com/callback"
        }, headers: client_auth

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("invalid_request")
        expect(json["error_description"]).to eq("code_verifier is required")
      end
    end

    context "with plain code challenge" do
      let(:code_verifier) { "plain-simple-key-12345" }
      let(:auth_code) { SecureRandom.hex(16) }

      before do
        Rails.cache.write("oauth_code_#{auth_code}", {
          user_id: user.id,
          client_id: sso_client.client_id,
          scopes: "openid profile email",
          redirect_uri: "https://client.example.com/callback",
          code_challenge: code_verifier,
          code_challenge_method: "plain"
        }, expires_in: 5.minutes)
      end

      it "succeeds when matching code_verifier is provided" do
        post oauth_token_path, params: {
          grant_type: "authorization_code",
          code: auth_code,
          redirect_uri: "https://client.example.com/callback",
          code_verifier: code_verifier
        }, headers: client_auth

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
      end

      it "fails when code_verifier mismatches" do
        post oauth_token_path, params: {
          grant_type: "authorization_code",
          code: auth_code,
          redirect_uri: "https://client.example.com/callback",
          code_verifier: "mismatching-verifier"
        }, headers: client_auth

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("invalid_grant")
      end
    end

    context "without PKCE challenge (backward compatibility)" do
      let(:auth_code) { SecureRandom.hex(16) }

      before do
        Rails.cache.write("oauth_code_#{auth_code}", {
          user_id: user.id,
          client_id: sso_client.client_id,
          scopes: "openid profile email",
          redirect_uri: "https://client.example.com/callback"
        }, expires_in: 5.minutes)
      end

      it "succeeds to exchange code without code_verifier" do
        post oauth_token_path, params: {
          grant_type: "authorization_code",
          code: auth_code,
          redirect_uri: "https://client.example.com/callback"
        }, headers: client_auth

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
      end
    end
  end
end
