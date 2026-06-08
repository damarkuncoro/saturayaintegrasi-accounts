require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", tenant: tenant, verified: true) }

  def sign_in_as(user)
    post sign_in_path, params: { email: user.email, password: "Secret1*3*5*" }
  end

  describe 'GET /sessions' do
    context 'when signed in' do
      it 'returns success' do
        sign_in_as(user)
        get sessions_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in' do
        get sessions_path
        expect(response).to redirect_to(sign_in_path)
      end
    end
  end

  describe 'GET /login' do
    it 'returns success' do
      get sign_in_path
      expect(response).to have_http_status(:success)
    end

    context 'when already signed in' do
      it 'redirects to the user dashboard' do
        sign_in_as(user)
        get sign_in_path
        expect(response).to redirect_to("/dashboard")
      end
    end
  end

  describe 'POST /login' do
    context 'with valid credentials' do
      it 'signs in and redirects to worker dashboard' do
        post sign_in_path, params: { email: user.email, password: "Secret1*3*5*" }
        expect(response).to redirect_to("/dashboard")

        get "/dashboard"
        expect(response).to have_http_status(:success)
      end

      it 'authenticates duplicate emails within the current request tenant only' do
        first_tenant = create(:tenant, domain: "tenant-one.example.com")
        second_tenant = create(:tenant, domain: "tenant-two.example.com")
        email = "shared@example.com"

        create(
          :user,
          email: email,
          password: "Secret1*3*5*",
          password_confirmation: "Secret1*3*5*",
          tenant: first_tenant,
          verified: true
        )
        create(
          :user,
          email: email,
          password: "OtherSecret1*3*5*",
          password_confirmation: "OtherSecret1*3*5*",
          tenant: second_tenant,
          verified: true
        )

        host! second_tenant.domain

        post sign_in_path, params: { email: email, password: "Secret1*3*5*" }
        expect(response).to redirect_to(sign_in_path(email_hint: email))

        post sign_in_path, params: { email: email, password: "OtherSecret1*3*5*" }
        expect(response).to redirect_to("/dashboard")
      end
    end

    context 'with invalid credentials' do
      it 'redirects to login path with email hint and sets flash alert' do
        post sign_in_path, params: { email: user.email, password: "wrongpassword" }
        expect(response).to redirect_to(sign_in_path(email_hint: user.email))
        expect(flash[:alert]).to eq("Email atau kata sandi salah.")
      end
    end
  end

  describe 'DELETE /sessions/:id' do
    it 'signs out and redirects' do
      sign_in_as(user)
      session_id = user.sessions.last.id
      delete session_path(session_id)
      expect(response).to redirect_to(sessions_path)

      get sessions_path
      expect(response).to redirect_to(sign_in_path)
    end
  end
end
