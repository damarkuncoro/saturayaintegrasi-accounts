# frozen_string_literal: true

require "rails_helper"

RSpec.describe "JWT Secret Rotation Fallback", type: :request do
  let!(:tenant) { create(:tenant, domain: "rotation.example.com") }
  let!(:user) { create(:user, tenant: tenant, role: :user, verified: true) }
  let!(:sso_client) do
    Identity::SsoClientConfiguration.create!(
      tenant: tenant,
      client_name: "rotation-app",
      client_id: "rotation_client_id",
      client_secret: "secret",
      redirect_uris: [ "https://client.example.com/callback" ],
      active: true
    )
  end

  let!(:service_client) do
    Identity::ServiceClient.create!(
      tenant: tenant,
      service_name: "rotation-service",
      client_id: "rotation_service_id",
      secret: "supersecret",
      allowed_scopes: [ "introspect" ],
      active: true
    )
  end

  let(:backup_secret) { "old_secret_key_base_123456" }
  let(:now) { Time.current.to_i }

  # Token signed with backup/old secret key
  let(:payload) do
    {
      iss: "https://rotation.example.com",
      sub: user.id.to_s,
      tenant_id: tenant.id.to_s,
      aud: sso_client.client_id,
      exp: 1.hour.from_now.to_i,
      iat: now,
      scopes: "openid profile email"
    }
  end
  let(:token_signed_with_backup) { JWT.encode(payload, backup_secret, "HS256") }

  before do
    host! "rotation.example.com"
  end

  describe "OauthController secret fallback" do
    context "when JWT_SECRET_FALLBACKS is configured with the old key" do
      before do
        stub_const("ENV", ENV.to_h.merge("JWT_SECRET_FALLBACKS" => "another_secret, #{backup_secret}"))
      end

      it "successfully decodes the token at /oauth/userinfo" do
        get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{token_signed_with_backup}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["sub"]).to eq(user.id.to_s)
        expect(json["email"]).to eq(user.email)
      end

      it "successfully decodes the token at /oauth/introspect" do
        auth_header = { "Authorization" => "Basic " + Base64.encode64("rotation_service_id:supersecret").strip }
        post oauth_introspect_path, params: { token: token_signed_with_backup }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["active"]).to be true
        expect(json["user_id"]).to eq(user.id.to_s)
      end
    end

    context "when JWT_SECRET_FALLBACKS is not configured with the old key" do
      before do
        stub_const("ENV", ENV.to_h.merge("JWT_SECRET_FALLBACKS" => "some_other_secret"))
      end

      it "fails to decode the token at /oauth/userinfo" do
        get oauth_userinfo_path, headers: { "Authorization" => "Bearer #{token_signed_with_backup}" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns active: false at /oauth/introspect" do
        auth_header = { "Authorization" => "Basic " + Base64.encode64("rotation_service_id:supersecret").strip }
        post oauth_introspect_path, params: { token: token_signed_with_backup }, headers: auth_header

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["active"]).to be false
      end
    end
  end

  describe "Services::Identity::JwtService secret fallback" do
    let(:internal_payload) do
      {
        user_id: user.id,
        tenant_id: tenant.id,
        iss: SatuRayaCommons::Config.jwt_issuer,
        exp: 1.hour.from_now.to_i,
        iat: now,
        jti: SecureRandom.uuid
      }
    end
    let(:internal_token) { JWT.encode(internal_payload, backup_secret, "HS256") }

    context "when fallback key is configured" do
      before do
        stub_const("ENV", ENV.to_h.merge("JWT_SECRET_FALLBACKS" => backup_secret))
      end

      it "decodes the token successfully" do
        jwt_token = Services::Identity::JwtService.decode(internal_token)
        expect(jwt_token).to be_present
        expect(jwt_token.value).to eq(internal_token)
      end
    end

    context "when fallback key is not configured" do
      before do
        stub_const("ENV", ENV.to_h.merge("JWT_SECRET_FALLBACKS" => "wrong_secret"))
      end

      it "returns nil" do
        jwt_token = Services::Identity::JwtService.decode(internal_token)
        expect(jwt_token).to be_nil
      end
    end
  end
end
