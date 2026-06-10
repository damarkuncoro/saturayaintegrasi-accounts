require "rails_helper"

RSpec.describe "Accounts main scenarios", type: :request do
  let(:password) { "Secret1*3*5*" }

  def sign_in_as(user, password: self.password)
    post sign_in_path, params: { email: user.email, password: password }
  end

  it "runs registration, tenant-scoped login, session listing, and logout" do
    host! "tenant-one.example.com"
    create(:tenant, domain: "tenant-one.example.com")
    tenant_two = create(:tenant, domain: "tenant-two.example.com")

    post sign_up_path, params: {
      user: {
        email: "public-admin-attempt@example.com",
        password: password,
        password_confirmation: password,
        first_name: "Public",
        last_name: "User",
        phone: "628123456789",
        role: "admin"
      }
    }

    registered_user = Identity::User.find_by!(email: "public-admin-attempt@example.com")
    expect(response.location).to include("/dashboard")
    expect(registered_user).to be_user

    delete sign_out_path

    email = "shared-login@example.com"
    create(
      :user,
      email: email,
      password: password,
      password_confirmation: password,
      tenant: System::Tenant.find_by!(domain: "tenant-one.example.com"),
      verified: true
    )
    tenant_two_user = create(
      :user,
      email: email,
      password: "OtherSecret1*3*5*",
      password_confirmation: "OtherSecret1*3*5*",
      tenant: tenant_two,
      verified: true
    )

    host! tenant_two.domain

    post sign_in_path, params: { email: email, password: password }
    expect(response.location).to match(/\/login\?email_hint=shared-login%40example\.com$/)

    post sign_in_path, params: { email: email, password: "OtherSecret1*3*5*" }
    expect(response.location).to include("/dashboard")

    get sessions_path
    expect(response).to have_http_status(:success)

    delete sign_out_path
    get sessions_path
    expect(response.location).to match(/\/login$/)
  end

  it "runs email verification, email change, password change, and password reset" do
    host! "email-flow.example.com"
    tenant = create(:tenant, domain: "email-flow.example.com")
    user = create(
      :user,
      email: "email-flow@example.com",
      password: password,
      password_confirmation: password,
      tenant: tenant,
      verified: false
    )

    sign_in_as(user)

    expect {
      post identity_email_verification_path
    }.to have_enqueued_mail(Identity::UserMailer, :email_verification_instructions)
      .with(user, kind_of(String))

    token_raw = "some_raw_token"
    token_digest = Digest::SHA256.hexdigest(token_raw)
    user.email_verification_tokens.create!(tenant: tenant, token_digest: token_digest, expires_at: 1.day.from_now)

    get identity_email_verification_path(sid: token_raw, email: user.email)
    expect(response.location).to include("/dashboard")
    expect(user.reload).to be_verified

    patch identity_email_path, params: {
      email: "email-flow-updated@example.com",
      password_challenge: password
    }
    expect(response.location).to include("/dashboard")
    expect(user.reload.email).to eq("email-flow-updated@example.com")
    expect(user).not_to be_verified

    patch password_path, params: {
      password_challenge: password,
      password: "NewSecret1*3*5*",
      password_confirmation: "NewSecret1*3*5*"
    }
    expect(response.location).to include("/dashboard")

    user.reload.update!(verified: true)

    expect {
      post identity_password_reset_path, params: { email: user.email }
    }.to have_enqueued_mail(Identity::UserMailer, :password_reset_instructions)
      .with(user, kind_of(String))

    token_raw = "reset_raw_token"
    token_digest = Digest::SHA256.hexdigest(token_raw)
    user.password_reset_tokens.create!(tenant: tenant, token_digest: token_digest, expires_at: 1.day.from_now)

    patch identity_password_reset_path, params: {
      sid: token_raw,
      password: "ResetSecret1*3*5*",
      password_confirmation: "ResetSecret1*3*5*"
    }
    expect(response.location).to match(/\/login$/)
  end

  it "runs 2FA setup, login challenge, and secure disable" do
    tenant = create(:tenant, domain: "two-fa.example.com")
    user = create(:user, password: password, password_confirmation: password, tenant: tenant, verified: true)

    host! "two-fa.example.com"
    sign_in_as(user)
    get two_factor_settings_path
    setup_code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now

    post enable_two_factor_settings_path, params: {
      otp_code: setup_code,
      password_challenge: password
    }
    expect(response).to have_http_status(:success), "Expected success but got #{response.status}: #{response.body}"
    expect(response.body).to include("Kode Cadangan")
    expect(user.reload).to be_otp_required_for_login

    delete sign_out_path

    post sign_in_path, params: { email: user.email, password: password }
    expect(response.location).to include(new_two_factor_challenge_path)

    challenge_code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now
    post two_factor_challenge_path, params: { otp_code: challenge_code }
    expect(response.location).to include("/dashboard")

    disable_code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now
    post disable_two_factor_settings_path, params: {
      otp_code: disable_code,
      password_challenge: password
    }
    expect(response.location).to include(two_factor_settings_path)
    expect(user.reload).not_to be_otp_required_for_login
    expect(user.otp_secret).to be_nil
  end

  it "runs JWT, permissions, long-term identity metadata, SSO config, and user sync event" do
    tenant = create(:tenant)
    user = create(:user, tenant: tenant, verified: true)

    token = user.generate_jwt_token
    expect(Identity::User.decode_jwt_token(token)).to eq(user)

    create(:user_permission, user: user, tenant: tenant, action: "manage", resource_type: "Identity::User")
    expect(user.can?("manage", "Identity::User")).to be true
    expect(user.can?("read", "Identity::User")).to be false

    passkey = create(:user_passkey, user: user, tenant: tenant)
    consent = create(:user_consent, user: user, tenant: tenant)
    trusted_device = create(:trusted_device, user: user, tenant: tenant)
    sso_client = create(:sso_client_configuration, tenant: tenant)

    expect(passkey).to be_persisted
    expect(consent).to be_persisted
    expect(trusted_device).to be_persisted
    expect(sso_client.client_id).to start_with("client_")

    expect {
      UseCases::PublishUserSyncEvent.new.execute(action: "update", user: user)
    }.to have_enqueued_job(Identity::UserSyncJob)
      .with(hash_including(action: "update", user: hash_including(id: user.id, tenant_id: tenant.id)))
  end
end
