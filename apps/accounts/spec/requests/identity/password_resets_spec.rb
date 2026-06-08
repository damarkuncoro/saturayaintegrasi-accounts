require 'rails_helper'

RSpec.describe 'Identity::PasswordResets', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:tenant) { create(:tenant, domain: "password-reset.example.com") }
  let!(:user) { create(:user, tenant: tenant, verified: true) }

  before do
    host! tenant.domain
  end

  def create_password_reset_token(user, expires_at: 2.hours.from_now)
    user.password_reset_tokens.create!(
      tenant: user.tenant,
      token_digest: SecureRandom.hex(32),
      expires_at: expires_at
    )
  end

  describe 'GET /identity/password_reset/new' do
    it 'returns success' do
      get new_identity_password_reset_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /identity/password_reset/edit' do
    it 'returns success with a valid token' do
      token = create_password_reset_token(user)
      get edit_identity_password_reset_path(sid: token.token_digest)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /identity/password_reset' do
    context 'with a valid verified email' do
      it 'queues a password reset email and redirects' do
      expect {
        post identity_password_reset_path, params: { email: user.email }
      }.to have_enqueued_mail(Identity::UserMailer, :password_reset_instructions)
        .with(user, kind_of(String))

      expect(response).to redirect_to(sign_in_path)
    end
    end

    context 'with a nonexistent email' do
      it 'does not queue an email and redirects with a generic message' do
        expect {
          post identity_password_reset_path, params: { email: 'nonexistent@example.com' }
        }.not_to have_enqueued_mail(Identity::UserMailer, :password_reset)

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:notice]).to eq("Instruksi reset kata sandi telah dikirim jika email terdaftar.")
      end
    end

    context 'with an unverified email' do
      it 'does not queue an email and redirects with a generic message' do
        user.update!(verified: false)

        expect {
          post identity_password_reset_path, params: { email: user.email }
        }.not_to have_enqueued_mail(Identity::UserMailer, :password_reset)

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:notice]).to eq("Instruksi reset kata sandi telah dikirim jika email terdaftar.")
      end
    end
  end

  describe 'PATCH /identity/password_reset' do
    context 'with a valid token' do
      it 'updates password and redirects to sign in' do
        token = create_password_reset_token(user)
        patch identity_password_reset_path, params: { sid: token.token_digest, password: "Secret6*4*2*", password_confirmation: "Secret6*4*2*" }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context 'with an expired token' do
      it 'does not update password and redirects with alert' do
        token = create_password_reset_token(user, expires_at: 1.minute.ago)

        patch identity_password_reset_path, params: { sid: token.token_digest, password: "Secret6*4*2*", password_confirmation: "Secret6*4*2*" }
        expect(response).to redirect_to(new_identity_password_reset_path)
        expect(flash[:alert]).to eq("Token reset kata sandi tidak valid atau sudah kedaluwarsa.")
      end
    end
  end
end
