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
    expect(response).to redirect_to("/dashboard")
    expect(registered_user).to be_worker

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
    expect(response).to redirect_to(sign_in_path(email_hint: email))

    post sign_in_path, params: { email: email, password: "OtherSecret1*3*5*" }
    expect(response).to redirect_to("/dashboard")

    get sessions_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include(tenant_two_user.email)

    delete sign_out_path
    get sessions_path
    expect(response).to redirect_to(sign_in_path)
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
    }.to have_enqueued_mail(Identity::UserMailer, :email_verification)
      .with(params: { user: user, token: kind_of(String) }, args: [])

    get identity_email_verification_path(sid: user.email_verification_tokens.order(created_at: :desc).first.token_digest)
    expect(response).to redirect_to("/dashboard")
    expect(user.reload).to be_verified

    patch identity_email_path, params: {
      email: "email-flow-updated@example.com",
      password_challenge: password
    }
    expect(response).to redirect_to("/dashboard")
    expect(user.reload.email).to eq("email-flow-updated@example.com")
    expect(user).not_to be_verified

    patch password_path, params: {
      password_challenge: password,
      password: "NewSecret1*3*5*",
      password_confirmation: "NewSecret1*3*5*"
    }
    expect(response).to redirect_to("/dashboard")

    user.reload.update!(verified: true)

    expect {
      post identity_password_reset_path, params: { email: user.email }
    }.to have_enqueued_mail(Identity::UserMailer, :password_reset)
      .with(params: { user: user, token: kind_of(String) }, args: [])

    reset_token = user.reload.password_reset_tokens.order(created_at: :desc).first.token_digest
    patch identity_password_reset_path, params: {
      sid: reset_token,
      password: "ResetSecret1*3*5*",
      password_confirmation: "ResetSecret1*3*5*"
    }
    expect(response).to redirect_to(sign_in_path)
  end

  it "runs 2FA setup, login challenge, and secure disable" do
    user = create(:user, password: password, password_confirmation: password, verified: true)

    sign_in_as(user)
    get two_factor_settings_path
    setup_code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now

    post enable_two_factor_settings_path, params: {
      otp_code: setup_code,
      password_challenge: password
    }
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Kode Cadangan")
    expect(user.reload).to be_otp_required_for_login

    delete sign_out_path

    post sign_in_path, params: { email: user.email, password: password }
    expect(response).to redirect_to(new_two_factor_challenge_path)

    challenge_code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now
    post two_factor_challenge_path, params: { otp_code: challenge_code }
    expect(response).to redirect_to("/dashboard")

    disable_code = ROTP::TOTP.new(user.reload.otp_secret, issuer: SatuRayaIdentityClient::Identity::BrandConfig.name).now
    post disable_two_factor_settings_path, params: {
      otp_code: disable_code,
      password_challenge: password
    }
    expect(response).to redirect_to(two_factor_settings_path)
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

    passkey = create(:user_passkey, user: user)
    consent = create(:user_consent, user: user, tenant: tenant)
    trusted_device = create(:trusted_device, user: user)
    sso_client = create(:sso_client_configuration, tenant: tenant)

    expect(passkey).to be_persisted
    expect(consent).to be_persisted
    expect(trusted_device).to be_persisted
    expect(sso_client.client_id).to start_with("client_")

    expect {
      UseCases::PublishUserSyncEvent.new.call(action: "update", user: user)
    }.to have_enqueued_job(Identity::UserSyncJob)
      .with(hash_including(action: "update", user: hash_including(id: user.id, tenant_id: tenant.id)))
  end
end
