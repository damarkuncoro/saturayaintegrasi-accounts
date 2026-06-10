require "rails_helper"

RSpec.describe "Auth cookie configuration", type: :request do
  let(:tenant) { create(:tenant, domain: "cookie.example.com") }
  let(:password) { "Secret1*3*5*" }
  let(:user) { create(:user, password: password, password_confirmation: password, tenant: tenant, verified: true) }

  around do |example|
    previous = ENV["AUTH_SESSION_COOKIE_NAME"]
    ENV["AUTH_SESSION_COOKIE_NAME"] = "kacanggoreng_session_id"

    example.run
  ensure
    previous.nil? ? ENV.delete("AUTH_SESSION_COOKIE_NAME") : ENV["AUTH_SESSION_COOKIE_NAME"] = previous
  end

  it "uses the configured auth session cookie name for request authentication" do
    host! "cookie.example.com"
    post sign_in_path, params: { email: user.email, password: password }

    expect(response.location).to include("/dashboard")
    expect(cookies["kacanggoreng_session_id"]).to be_present

    get "/dashboard"

    expect(response).to have_http_status(:success)
  end
end
