require 'rails_helper'

RSpec.describe 'Identity::Emails', type: :request do
  let(:tenant) { create(:tenant, domain: "www.example.com") }
  let(:user) { create(:user, password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", tenant: tenant, verified: true) }

  def sign_in_as(user)
    post sign_in_path, params: { email: user.email, password: "Secret1*3*5*" }
  end

  before do
    host! "www.example.com"
    sign_in_as(user)
  end

  describe 'GET /identity/email/edit' do
    it 'returns success' do
      get edit_identity_email_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /identity/email' do
    context 'with correct password challenge' do
      it 'updates the email and redirects to user dashboard' do
        patch identity_email_path, params: { email: "new_email@hey.com", password_challenge: "Secret1*3*5*" }
        expect(response.location).to include("/dashboard")
      end
    end

    context 'with wrong password challenge' do
      it 'does not update email and returns unprocessable_entity' do
        patch identity_email_path, params: { email: "new_email@hey.com", password_challenge: "SecretWrong1*3" }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("tidak valid")
      end
    end
  end
end
