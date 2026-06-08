require "rails_helper"

RSpec.describe SatuRayaIdentityClient::Configuration do
  around do |example|
    keys = %w[
      ACCOUNTS_URL
      APP_DOMAIN
      APP_HOST
      ACCOUNTS_SUBDOMAIN
      IDENTITY_CLIENT_ID
      IDENTITY_CLIENT_SECRET
    ]
    previous = keys.to_h { |key| [ key, ENV[key] ] }
    keys.each { |key| ENV.delete(key) }

    example.run
  ensure
    previous.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  describe "#accounts_url" do
    it "builds the default accounts URL from the configured app domain" do
      ENV["APP_DOMAIN"] = "kacanggoreng.com"

      expect(described_class.new.accounts_url).to eq("https://accounts.kacanggoreng.com")
    end

    it "uses APP_HOST when configured" do
      ENV["APP_HOST"] = "auth.kacanggoreng.com"

      expect(described_class.new.accounts_url).to eq("https://auth.kacanggoreng.com")
    end

    it "lets ACCOUNTS_URL override the brand-derived URL" do
      ENV["APP_DOMAIN"] = "kacanggoreng.com"
      ENV["ACCOUNTS_URL"] = "https://login.kacanggoreng.com"

      expect(described_class.new.accounts_url).to eq("https://login.kacanggoreng.com")
    end
  end
end
