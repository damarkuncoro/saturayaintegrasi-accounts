# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack Rate Limiting", type: :request do
  let!(:tenant) { create(:tenant, domain: "rate-limit.example.com") }

  before(:each) do
    host! "rate-limit.example.com"
    Rack::Attack.enabled = true
    @old_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end

  after(:each) do
    Rack::Attack.enabled = false
    Rack::Attack.cache.store = @old_store
  end

  describe "login attempts throttling" do
    it "throttles by email after 10 attempts" do
      email = "login-throttle@example.com"

      10.times do
        post sign_in_path, params: { email: email, password: "wrong_password" }
        expect(response.status).not_to eq(429)
      end

      post sign_in_path, params: { email: email, password: "wrong_password" }
      expect(response.status).to eq(429)

      json = JSON.parse(response.body)
      expect(json["error"]).to include("Rate limit exceeded")
    end
  end

  describe "registrations throttling" do
    it "throttles registrations by IP after 10 attempts" do
      10.times do
        post sign_up_path, params: { user: { email: "some@example.com" } }
        expect(response.status).not_to eq(429)
      end

      post sign_up_path, params: { user: { email: "some@example.com" } }
      expect(response.status).to eq(429)

      json = JSON.parse(response.body)
      expect(json["error"]).to include("Rate limit exceeded")
    end
  end

  describe "password resets throttling" do
    it "throttles password reset requests by IP after 10 attempts" do
      10.times do |i|
        post identity_password_reset_path, params: { email: "reset#{i}@example.com" }
        expect(response.status).not_to eq(429)
      end

      post identity_password_reset_path, params: { email: "reset10@example.com" }
      expect(response.status).to eq(429)

      json = JSON.parse(response.body)
      expect(json["error"]).to include("Rate limit exceeded")
    end

    it "throttles password reset requests by email after 5 attempts" do
      # Note: Since the IP limit is 10, the email limit (5) should trigger first.
      # To test this, we can vary the IP using a header or just make requests to the email.
      # Let's perform requests for the same email.
      email = "user-reset@example.com"

      5.times do
        post identity_password_reset_path, params: { email: email }
        expect(response.status).not_to eq(429)
      end

      post identity_password_reset_path, params: { email: email }
      expect(response.status).to eq(429)
    end
  end
end
