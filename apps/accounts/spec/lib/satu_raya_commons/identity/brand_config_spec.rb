require "rails_helper"

RSpec.describe SatuRayaIdentityClient::Identity::BrandConfig do
  around do |example|
    keys = %w[
      BRAND_NAME
      BRAND_SLUG
      APP_DOMAIN
      APP_HOST
      ACCOUNTS_SUBDOMAIN
      BRAND_PRIMARY_COLOR
      BRAND_LOGO_URL
      BRAND_PRIVACY_URL
      BRAND_TERMS_URL
      BRAND_SUPPORT_EMAIL
      SESSION_COOKIE_NAME
      AUTH_SESSION_COOKIE_NAME
      TRUSTED_DEVICE_COOKIE_NAME
      SESSION_COOKIE_DOMAIN
      ALLOWED_REDIRECT_HOSTS
    ]
    previous = keys.to_h { |key| [ key, ENV[key] ] }
    keys.each { |key| ENV.delete(key) }

    example.run
  ensure
    previous.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  describe ".name" do
    it "defaults to Satu Raya" do
      expect(described_class.name).to eq("Satu Raya")
    end

    it "reads the configured brand name" do
      ENV["BRAND_NAME"] = "Kacang Goreng"

      expect(described_class.name).to eq("Kacang Goreng")
    end
  end

  describe ".accounts_host" do
    it "defaults to accounts on the configured app domain" do
      ENV["APP_DOMAIN"] = "kacanggoreng.com"

      expect(described_class.accounts_host).to eq("accounts.kacanggoreng.com")
    end

    it "uses APP_HOST when provided" do
      ENV["APP_HOST"] = "auth.kacanggoreng.com"

      expect(described_class.accounts_host).to eq("auth.kacanggoreng.com")
    end
  end

  describe ".session_cookie_domain" do
    it "keeps the existing wildcard behavior by default" do
      expect(described_class.session_cookie_domain).to eq(:all)
    end

    it "can be pinned to a specific root domain" do
      ENV["SESSION_COOKIE_DOMAIN"] = ".kacanggoreng.com"

      expect(described_class.session_cookie_domain).to eq(".kacanggoreng.com")
    end
  end

  describe ".auth_session_cookie_name" do
    it "keeps the existing auth session cookie name by default" do
      expect(described_class.auth_session_cookie_name).to eq("session_id")
    end

    it "can be configured per deployment" do
      ENV["AUTH_SESSION_COOKIE_NAME"] = "kacanggoreng_session_id"

      expect(described_class.auth_session_cookie_name).to eq("kacanggoreng_session_id")
    end
  end

  describe ".trusted_device_cookie_name" do
    it "keeps the existing trusted device cookie name by default" do
      expect(described_class.trusted_device_cookie_name).to eq("remember_device")
    end

    it "can be configured per deployment" do
      ENV["TRUSTED_DEVICE_COOKIE_NAME"] = "kacanggoreng_remember_device"

      expect(described_class.trusted_device_cookie_name).to eq("kacanggoreng_remember_device")
    end
  end

  describe ".allowed_redirect_hosts" do
    it "builds default hosts from APP_DOMAIN" do
      ENV["APP_DOMAIN"] = "kacanggoreng.com"

      expect(described_class.allowed_redirect_hosts).to eq([
        "kacanggoreng.com",
        "accounts.kacanggoreng.com"
      ])
    end

    it "uses the explicit redirect host allowlist" do
      ENV["ALLOWED_REDIRECT_HOSTS"] = "app.kacanggoreng.com, admin.kacanggoreng.com"

      expect(described_class.allowed_redirect_hosts).to eq([ "app.kacanggoreng.com", "admin.kacanggoreng.com" ])
    end
  end
end
