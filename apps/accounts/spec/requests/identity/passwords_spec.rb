require 'rails_helper'

RSpec.describe 'Passwords', type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", tenant: tenant, verified: true) }

  def sign_in_as(user)
    post sign_in_path, params: { email: user.email, password: "Secret1*3*5*" }
  end

  before do
    sign_in_as(user)
  end

  describe 'GET /password/edit' do
    it 'returns success' do
      get edit_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /password' do
    context 'with valid current password (challenge) and new password' do
      it 'updates the password and redirects to user dashboard' do
        patch password_path, params: {
          password_challenge: "Secret1*3*5*",
          password: "NewPass123!@#",
          password_confirmation: "NewPass123!@#"
        }
        expect(response).to redirect_to("/dashboard")
      end
    end

    context 'with incorrect password challenge' do
      it 'does not update the password and returns unprocessable_entity with an error message' do
        patch password_path, params: {
          password_challenge: "SecretWrong1*3",
          password: "NewPass123!@#",
          password_confirmation: "NewPass123!@#"
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("tidak valid")
      end
    end
  end
end
