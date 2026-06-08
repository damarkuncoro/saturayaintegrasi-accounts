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
      }.to have_enqueued_mail(Identity::UserMailer, :email_verification_instructions)
        .with(user, kind_of(String))

      expect(response).to redirect_to("/dashboard")
    end
  end

  describe 'GET /identity/email_verification' do
    context 'with a valid token' do
      it 'verifies the email and redirects to user dashboard' do
        token_raw = SecureRandom.hex(32)
        token_digest = Digest::SHA256.hexdigest(token_raw)
        
        user.email_verification_tokens.create!(
          tenant: tenant,
          token_digest: token_digest,
          expires_at: 24.hours.from_now
        )

        get identity_email_verification_path(sid: token_raw, email: user.email)
        expect(response).to redirect_to("/dashboard")
      end
    end

    context 'with an expired token' do
      it 'does not verify the email and redirects with alert' do
        token_raw = SecureRandom.hex(32)
        token_digest = Digest::SHA256.hexdigest(token_raw)

        user.email_verification_tokens.create!(
          tenant: tenant,
          token_digest: token_digest,
          expires_at: 1.hour.ago
        )

        get identity_email_verification_path(sid: token_raw, email: user.email)
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq("Token tidak valid atau sudah kedaluwarsa.")
      end
    end
  end
end
