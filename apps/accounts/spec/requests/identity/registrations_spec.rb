require 'rails_helper'

RSpec.describe 'Registrations', type: :request do
  let!(:tenant) { create(:tenant, domain: "www.example.com") }

  before do
    host! "www.example.com"
  end

  describe 'GET /register' do
    it 'returns success' do
      get sign_up_path
      expect(response).to have_http_status(:success)
    end

    context 'when already signed in' do
      let(:user) { create(:user, password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", tenant: tenant, verified: true) }

      it 'redirects to the user dashboard' do
        post sign_in_path, params: { email: user.email, password: "Secret1*3*5*" }
        get sign_up_path
        expect(response.location).to include("/dashboard")
      end
    end
  end

  describe 'POST /register' do
    context 'with valid user params' do
      it 'creates a new user and redirects to user dashboard' do
        expect {
          post sign_up_path, params: {
            user: {
              email: 'lazaronixon@hey.com',
              password: 'Secret1*3*5*',
              password_confirmation: 'Secret1*3*5*',
              first_name: 'Lazaro',
              last_name: 'Nixon',
              phone: '1234567890'
            }
          }
        }.to change(Identity::User, :count).by(1)

        expect(response.location).to include("/dashboard")
      end

      it 'does not allow public registration as an admin' do
        expect {
          post sign_up_path, params: {
            user: {
              email: 'admin-attempt@example.com',
              password: 'Secret1*3*5*',
              password_confirmation: 'Secret1*3*5*',
              first_name: 'Admin',
              last_name: 'Attempt',
              phone: '1234567890',
              role: 'admin'
            }
          }
        }.to change(Identity::User, :count).by(1)

        expect(Identity::User.find_by(email: 'admin-attempt@example.com')).to be_user
      end
    end

    context 'with invalid user params' do
      it 'does not create a new user and returns unprocessable_entity' do
        expect {
          post sign_up_path, params: {
            user: {
              email: 'invalidemail',
              password: '123',
              password_confirmation: 'wrong'
            }
          }
        }.not_to change(Identity::User, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
