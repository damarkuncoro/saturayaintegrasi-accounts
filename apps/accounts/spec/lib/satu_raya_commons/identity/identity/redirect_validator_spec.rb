require "rails_helper"

RSpec.describe SatuRayaIdentityClient::Identity::RedirectValidator do
  let(:domain) { SatuRayaIdentityClient::Identity::BrandConfig.app_domain }
  let(:allowed_hosts) { [ domain, "app.kacanggoreng.com" ] }

  describe ".safe_url" do
    it "allows relative paths" do
      expect(described_class.safe_url("/dashboard", fallback: "/fallback", allowed_hosts: allowed_hosts)).to eq("/dashboard")
    end

    it "allows explicitly configured hosts" do
      url = "https://app.kacanggoreng.com/dashboard"

      expect(described_class.safe_url(url, fallback: "/fallback", allowed_hosts: allowed_hosts)).to eq(url)
    end

    it "allows subdomains of configured root hosts" do
      url = "https://jobs.#{domain}/dashboard"

      expect(described_class.safe_url(url, fallback: "/fallback", allowed_hosts: allowed_hosts)).to eq(url)
    end

    it "rejects external hosts" do
      expect(
        described_class.safe_url("https://attacker.example/dashboard", fallback: "/fallback", allowed_hosts: allowed_hosts)
      ).to eq("/fallback")
    end

    it "rejects suffix lookalike hosts" do
      expect(
        described_class.safe_url("https://attacker-#{domain}/dashboard", fallback: "/fallback", allowed_hosts: allowed_hosts)
      ).to eq("/fallback")
    end

    it "rejects protocol-relative URLs" do
      expect(described_class.safe_url("//attacker.example", fallback: "/fallback", allowed_hosts: allowed_hosts)).to eq("/fallback")
    end
  end
end
