require 'rails_helper'

RSpec.describe 'Identity::EmailVerifications', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:tenant) { create(:tenant, domain: "email-verification.example.com") }
  let(:user) { create(:user, password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", tenant: tenant, verified: false) }

  def sign_in_as(user)
    post sign_in_path, params: { email: user.email, password: "Secret1*3*5*" }
  end

  before do
    host! tenant.domain
    sign_in_as(user)
  end

  describe 'POST /identity/email_verification' do
    it 'queues a verification email and redirects' do
      expect {
        post identity_email_verification_path
      }.to have_enqueued_mail(Identity::UserMailer, :email_verification)
        .with(params: { user: user, token: kind_of(String) }, args: [])

      expect(response).to redirect_to("/dashboard")
    end
  end

  describe 'GET /identity/email_verification' do
    context 'with a valid token' do
      it 'verifies the email and redirects to user dashboard' do
        token = user.email_verification_tokens.create!(
          tenant: tenant,
          token_digest: SecureRandom.hex(32),
          expires_at: 24.hours.from_now
        )

        sid = token.token_digest
        get identity_email_verification_path(sid: sid, email: user.email)
        expect(response).to redirect_to("/dashboard")
      end
    end

    context 'with an expired token' do
      it 'does not verify the email and redirects with alert' do
        token = user.email_verification_tokens.create!(
          tenant: tenant,
          token_digest: SecureRandom.hex(32),
          expires_at: 1.hour.ago
        )

        get identity_email_verification_path(sid: token.token_digest, email: user.email)
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq("Token verifikasi tidak valid atau sudah kedaluwarsa.")
      end
    end
  end
end
