# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC / OAuth2 Provider Flow", type: :request do
  let!(:tenant) { create(:tenant, domain: "oauth.example.com") }
  let!(:user) { create(:user, tenant: tenant, verified: true) }
  let!(:sso_client) do
    create(
      :sso_client_configuration,
      tenant: tenant,
      client_secret: "supersecret",
      redirect_uris: ["https://client.example.com/callback"]
    )
  end
  let(:password) { "Password123!456" }

  before do
    host! "oauth.example.com"
    Rails.cache.clear
  end

  describe "GET /oauth/authorize" do
    context "when unauthenticated" do
      it "redirects to the login page with return_to parameter" do
        get oauth_authorize_path, params: {
          client_id: sso_client.client_id,
          redirect_uri: "https://client.example.com/callback",
          response_type: "code",
          scope: "openid profile email",
          state: "xyz"
        }

        expect(response).to redirect_to(sign_in_url(return_to: request.fullpath))
      end
    end

    context "when authenticated" do
      before do
        post sign_in_path, params: { email: user.email, password: password }
        expect(response).to redirect_to("/dashboard")
      end

      context "without existing consent" do
        it "renders the authorize consent page" do
          get oauth_authorize_path, params: {
            client_id: sso_client.client_id,
            redirect_uri: "https://client.example.com/callback",
            response_type: "code",
            scope: "openid profile email",
            state: "xyz"
          }

          expect(response).to have_http_status(:success)
          expect(response.body).to include("Persetujuan Akses")
        end
      end

      context "with existing consent" do
        before do
          create(
            :user_consent,
            user: user,
            tenant: tenant,
            sso_client_configuration: sso_client,
            consented_scopes: { "openid" => true, "profile" => true }
          )
        end

        it "skips the consent screen and redirects with auth code" do
          get oauth_authorize_path, params: {
            client_id: sso_client.client_id,
            redirect_uri: "https://client.example.com/callback",
            response_type: "code",
            scope: "openid profile",
            state: "xyz"
          }

          expect(response.status).to eq(302)
          expect(response.location).to start_with("https://client.example.com/callback?code=")
          expect(response.location).to include("state=xyz")
        end
      end
    end
  end

  describe "POST /oauth/consent" do
    before do
      post sign_in_path, params: { email: user.email, password: password }
      
      get oauth_authorize_path, params: {
        client_id: sso_client.client_id,
        redirect_uri: "https://client.example.com/callback",
        response_type: "code",
        scope: "openid profile email",
        state: "xyz"
      }
    end

    context "when user denies consent" do
      it "redirects back to the client redirect URI with an access_denied error" do
        post oauth_consent_path, params: {
          client_id: sso_client.client_id,
          allow: "false"
        }

        expect(response).to redirect_to("https://client.example.com/callback?error=access_denied")
      end
    end

    context "when user allows consent" do
      it "creates a UserConsent record and redirects with an auth code" do
        expect {
          post oauth_consent_path, params: {
            client_id: sso_client.client_id,
            allow: "true"
          }
        }.to change { Identity::UserConsent.count }.by(1)

        expect(response.status).to eq(302)
        expect(response.location).to start_with("https://client.example.com/callback?code=")
        expect(response.location).to include("state=xyz")

        consent = Identity::UserConsent.last
        expect(consent.consented_scopes).to eq({
          "openid" => true,
          "profile" => true,
          "email" => true
        })
      end
    end
  end

  describe "POST /oauth/token" do
    let(:auth_code) { "test_auth_code_123" }

    before do
      Rails.cache.write("oauth_code_#{auth_code}", {
        user_id: user.id,
        client_id: sso_client.client_id,
        scopes: "openid profile email",
        redirect_uri: "https://client.example.com/callback"
      }, expires_in: 5.minutes)
    end

    context "with valid client credentials and code" do
      it "returns access token and ID token successfully" do
        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "supersecret",
          code: auth_code,
          grant_type: "authorization_code",
          redirect_uri: "https://client.example.com/callback"
        }

        expect(response.status).to eq(200)
        
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
        expect(json["id_token"]).to be_present
        expect(json["token_type"]).to eq("Bearer")
        expect(json["expires_in"]).to eq(3600)
        expect(json["scope"]).to eq("openid profile email")
      end
    end

    context "with invalid client credentials" do
      it "returns unauthorized error" do
        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "wrongsecret",
          code: auth_code,
          grant_type: "authorization_code",
          redirect_uri: "https://client.example.com/callback"
        }

        expect(response.status).to eq(418).or eq(401)
      end
    end
  end

  describe "GET /oauth/userinfo" do
    let(:now) { Time.current.to_i }
    let(:access_token_payload) do
      {
        iss: "https://oauth.example.com",
        sub: user.id.to_s,
        aud: sso_client.client_id,
        exp: 1.hour.from_now.to_i,
        iat: now,
        scopes: "openid profile email"
      }
    end
    let(:token) { JWT.encode(access_token_payload, Rails.application.secret_key_base, "HS256") }

    context "with valid Bearer token" do
      it "returns user information payload" do
        get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{token}" }

        expect(response.status).to eq(200)
        
        json = JSON.parse(response.body)
        expect(json["sub"]).to eq(user.id.to_s)
        expect(json["email"]).to eq(user.email)
        expect(json["name"]).to eq(user.full_name)
        expect(json["email_verified"]).to eq(user.email_verified?)
      end
    end

    context "with invalid Bearer token" do
      it "returns unauthorized" do
        get oauth_userinfo_path, headers: { "Authorization" => "Bearer invalid_token" }

        expect(response.status).to eq(401)
      end
    end
  end
end
