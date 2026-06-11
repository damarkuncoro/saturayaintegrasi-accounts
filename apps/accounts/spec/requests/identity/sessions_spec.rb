require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  let!(:tenant) { create(:tenant, domain: "www.example.com") }
  let(:user) { create(:user, password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*", tenant: tenant, verified: true) }

  before do
    host! "www.example.com"
  end

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
        expect(response.location).to match(/\/login$/)
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
        expect(response.location).to include("/dashboard")
      end
    end
  end

  describe 'POST /login' do
    context 'with valid credentials' do
      it 'signs in and redirects to user dashboard' do
        post sign_in_path, params: { email: user.email, password: "Secret1*3*5*" }
        expect(response.location).to include("/dashboard")

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
        expect(response.location).to match(/\/login\?email_hint=shared%40example\.com$/)

        post sign_in_path, params: { email: email, password: "OtherSecret1*3*5*" }
        expect(response.location).to match(/\/dashboard$/)
      end

      it 'creates a user_login audit log' do
        expect {
          post sign_in_path, params: { email: user.email, password: "Secret1*3*5*" }
        }.to change(System::AuditLog.where(action: "user_login"), :count).by(1)
      end
    end

    context 'with invalid credentials' do
      it 'redirects to login path with email hint and sets flash alert' do
        post sign_in_path, params: { email: user.email, password: "wrongpassword" }
        expect(response.location).to match(/\/login\?email_hint=#{Regexp.escape(user.email).gsub('@', '%40')}$/)
        expect(flash[:alert]).to eq("Email atau kata sandi salah.")
      end

      it 'creates a user_login_failed audit log' do
        expect {
          post sign_in_path, params: { email: user.email, password: "wrongpassword" }
        }.to change(System::AuditLog.where(action: "user_login_failed"), :count).by(1)
      end
    end
  end

  describe 'DELETE /sessions/:id' do
    it 'signs out and redirects' do
      sign_in_as(user)
      session_id = user.sessions.last.id
      delete session_path(session_id)
      expect(response.location).to include(sessions_path)
    end
  end

  describe 'DELETE /logout' do
    it 'signs out, revokes session, and creates session_revoked audit log' do
      sign_in_as(user)
      session_record = user.sessions.active.last
      expect(session_record).to be_present

      expect {
        delete sign_out_path
      }.to change(System::AuditLog.where(action: "session_revoked"), :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(session_record.reload.revoked?).to be true
    end
  end
end
