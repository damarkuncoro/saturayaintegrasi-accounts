require "rails_helper"

RSpec.describe "Two factor settings", type: :request do
  let(:tenant) { create(:tenant, domain: "www.example.com") }
  let(:password) { "Secret1*3*5*" }
  let(:user) { create(:user, password: password, password_confirmation: password, tenant: tenant, verified: true) }

  def sign_in_as(user)
    post sign_in_path, params: { email: user.email, password: password }
  end

  before do
    host! "www.example.com"
    sign_in_as(user)
  end

  describe "GET /two_factor_settings" do
    it "prepares a pending OTP secret without enabling 2FA" do
      get two_factor_settings_path

      expect(response).to have_http_status(:success)
      expect(user.reload.otp_secret).to be_present
      expect(user).not_to be_otp_required_for_login
    end
  end

  describe "POST /two_factor_settings/enable" do
    it "enables 2FA with a valid OTP and password challenge" do
      get two_factor_settings_path
      code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now

      post enable_two_factor_settings_path, params: {
        otp_code: code,
        password_challenge: password
      }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Kode Cadangan")
      expect(user.reload).to be_otp_required_for_login
    end

    it "rejects enablement with an invalid OTP" do
      get two_factor_settings_path

      post enable_two_factor_settings_path, params: {
        otp_code: "000000",
        password_challenge: password
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload).not_to be_otp_required_for_login
    end
  end

  describe "POST /two_factor_settings/disable" do
    before do
      user.enable_2fa!
    end

    it "disables 2FA with a valid OTP and password challenge" do
      code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now

      post disable_two_factor_settings_path, params: {
        otp_code: code,
        password_challenge: password
      }

      expect(response).to redirect_to(two_factor_settings_path)
      expect(user.reload).not_to be_otp_required_for_login
      expect(user.otp_secret).to be_nil
    end

    it "rejects disablement with an invalid password challenge" do
      code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now

      post disable_two_factor_settings_path, params: {
        otp_code: code,
        password_challenge: "wrong-password"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload).to be_otp_required_for_login
    end
  end
end
