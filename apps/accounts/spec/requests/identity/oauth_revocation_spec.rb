# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OIDC / OAuth2 Token Revocation", type: :request do
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

  let(:now) { Time.current.to_i }
  let(:access_token_payload) do
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
  let(:access_token) { JWT.encode(access_token_payload, Rails.application.secret_key_base, "HS256") }

  before do
    host! "oauth.example.com"
    Rails.cache.clear
    # Clear Redis blacklist keys to isolate test runs
    redis_url = ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
    redis = Redis.new(url: redis_url)
    keys = redis.keys("oauth_blacklisted_token:*")
    redis.del(*keys) if keys.any?
  end

  describe "POST /oauth/revoke" do
    context "revoking an access token" do
      it "adds the token hash to Redis blacklist and invalidates it for userinfo" do
        # Verify initially valid
        get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{access_token}" }
        expect(response).to have_http_status(:ok)

        # Revoke the token
        post oauth_revoke_path, params: { token: access_token }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ "status" => "revoked" })

        # Verify it is now unauthorized for userinfo
        get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{access_token}" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "invalidates the token for introspection" do
        auth_header = {
          "Authorization" => "Basic " + Base64.encode64("test_service_client_id:super_secure_service_secret_123").strip
        }

        # Verify initially active
        post oauth_introspect_path, params: { token: access_token }, headers: auth_header
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["active"]).to be true

        # Revoke the token
        post oauth_revoke_path, params: { token: access_token }
        expect(response).to have_http_status(:ok)

        # Verify it is now inactive
        post oauth_introspect_path, params: { token: access_token }, headers: auth_header
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["active"]).to be false
      end
    end

    context "revoking a refresh token" do
      let!(:refresh_token_value) { "rt_#{SecureRandom.hex(32)}" }
      let!(:refresh_token_digest) { Identity::JwtRefreshToken.digest(refresh_token_value) }
      let!(:refresh_token_record) do
        Identity::JwtRefreshToken.create!(
          tenant: tenant,
          user: user,
          sso_client_configuration: sso_client,
          token_digest: refresh_token_digest,
          family_id: SecureRandom.uuid,
          scopes: [ "openid", "profile" ],
          expires_at: 30.days.from_now
        )
      end

      it "marks the refresh token as revoked in the database" do
        expect(refresh_token_record.revoked?).to be false

        # Revoke the refresh token
        post oauth_revoke_path, params: { token: refresh_token_value }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ "status" => "revoked" })

        # Verify database record
        expect(refresh_token_record.reload.revoked?).to be true
      end

      it "causes subsequent token exchange using the refresh token to fail" do
        # Revoke it
        post oauth_revoke_path, params: { token: refresh_token_value }
        expect(response).to have_http_status(:ok)

        # Attempt to exchange it
        client_auth = {
          "Authorization" => "Basic " + Base64.encode64("#{sso_client.client_id}:supersecret").strip
        }
        post oauth_token_path, params: {
          grant_type: "refresh_token",
          refresh_token: refresh_token_value
        }, headers: client_auth

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("invalid_grant")
      end
    end

    context "with invalid/malformed token" do
      it "returns 200 OK and status revoked as per RFC 7009" do
        post oauth_revoke_path, params: { token: "this_is_not_a_valid_token" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ "status" => "revoked" })
      end
    end
  end
end
