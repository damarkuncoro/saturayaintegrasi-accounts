# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC Refresh Token Rotation (RTR)", type: :request do
  let!(:tenant) { create(:tenant, domain: "rtr.example.com") }
  let!(:user) { create(:user, tenant: tenant, role: :user, verified: true) }
  let!(:sso_client) do
    Identity::SsoClientConfiguration.create!(
      tenant: tenant,
      client_name: "test-app",
      client_id: "test_client_id",
      client_secret: "supersecret",
      redirect_uris: [ "https://client.example.com/callback" ],
      allowed_scopes: [ "openid", "profile", "email" ],
      active: true
    )
  end

  let(:auth_code) { "valid_code_123" }

  before do
    host! "rtr.example.com"
    Rails.cache.clear

    # Pre-cache code for authorization_code flow
    Rails.cache.write("oauth_code_#{auth_code}", {
      user_id: user.id,
      client_id: sso_client.client_id,
      scopes: "openid profile email",
      redirect_uri: "https://client.example.com/callback"
    }, expires_in: 5.minutes)
  end

  describe "POST /oauth/token" do
    context "with grant_type=authorization_code" do
      it "returns access token, ID token, and refresh token successfully" do
        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "supersecret",
          code: auth_code,
          grant_type: "authorization_code",
          redirect_uri: "https://client.example.com/callback"
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
        expect(json["id_token"]).to be_present
        expect(json["refresh_token"]).to be_present
        expect(json["token_type"]).to eq("Bearer")
        expect(json["scope"]).to eq("openid profile email")

        # Verify refresh token is stored in the database
        digest = Identity::JwtRefreshToken.digest(json["refresh_token"])
        record = Identity::JwtRefreshToken.find_by(token_digest: digest)
        expect(record).to be_present
        expect(record.user_id).to eq(user.id)
        expect(record.sso_client_configuration_id).to eq(sso_client.id)
        expect(record.scopes).to eq([ "openid", "profile", "email" ])
        expect(record).to be_active
      end
    end

    context "with grant_type=refresh_token" do
      let(:plain_token) { "rt_initial_token_secret_value" }
      let!(:refresh_token_record) do
        Identity::JwtRefreshToken.create!(
          tenant: tenant,
          user: user,
          sso_client_configuration: sso_client,
          token_digest: Identity::JwtRefreshToken.digest(plain_token),
          family_id: SecureRandom.uuid,
          scopes: [ "openid", "profile" ],
          expires_at: 30.days.from_now
        )
      end

      it "rotates the refresh token and returns new tokens" do
        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "supersecret",
          grant_type: "refresh_token",
          refresh_token: plain_token
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
        expect(json["refresh_token"]).to be_present
        expect(json["refresh_token"]).not_to eq(plain_token)
        expect(json["scope"]).to eq("openid profile")

        # Verify old refresh token is marked as revoked
        expect(refresh_token_record.reload).to be_revoked
        expect(refresh_token_record.replaced_by_id).to be_present

        # Verify new refresh token exists in DB with same family_id
        new_digest = Identity::JwtRefreshToken.digest(json["refresh_token"])
        new_record = Identity::JwtRefreshToken.find_by(token_digest: new_digest)
        expect(new_record).to be_present
        expect(new_record).to be_active
        expect(new_record.family_id).to eq(refresh_token_record.family_id)
        expect(new_record.replaced_by_id).to be_nil
        expect(refresh_token_record.replaced_by_id).to eq(new_record.id)
      end

      it "detects replay attack (re-using a revoked refresh token) and revokes the whole family" do
        # 1. First rotation
        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "supersecret",
          grant_type: "refresh_token",
          refresh_token: plain_token
        }
        expect(response).to have_http_status(:ok)
        first_rotation_json = JSON.parse(response.body)
        new_token = first_rotation_json["refresh_token"]

        # Verify first rotated token is active in DB
        new_record = Identity::JwtRefreshToken.find_by(token_digest: Identity::JwtRefreshToken.digest(new_token))
        expect(new_record).to be_active

        # 2. Replay attack: try using the initial token again
        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "supersecret",
          grant_type: "refresh_token",
          refresh_token: plain_token
        }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("invalid_grant")

        # Verify that all refresh tokens in the family are now revoked
        expect(refresh_token_record.reload).to be_revoked
        expect(new_record.reload).to be_revoked
      end

      it "fails if refresh token is expired" do
        refresh_token_record.update!(expires_at: 1.day.ago)

        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "supersecret",
          grant_type: "refresh_token",
          refresh_token: plain_token
        }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("invalid_grant")
      end

      it "fails if client_id does not match the token" do
        other_client = Identity::SsoClientConfiguration.create!(
          tenant: tenant,
          client_name: "other-app",
          client_id: "other_client_id",
          client_secret: "supersecret",
          redirect_uris: [ "https://client.example.com/callback" ],
          active: true
        )

        post oauth_token_path, params: {
          client_id: other_client.client_id,
          client_secret: "supersecret",
          grant_type: "refresh_token",
          refresh_token: plain_token
        }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("invalid_grant")
      end

      it "fails if user is inactive" do
        user.update!(active: false)

        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "supersecret",
          grant_type: "refresh_token",
          refresh_token: plain_token
        }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("invalid_grant")
      end

      it "fails if tenant is inactive" do
        tenant.update!(active: false)

        post oauth_token_path, params: {
          client_id: sso_client.client_id,
          client_secret: "supersecret",
          grant_type: "refresh_token",
          refresh_token: plain_token
        }

        # Tenant resolution failure returns 400 Bad Request
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
