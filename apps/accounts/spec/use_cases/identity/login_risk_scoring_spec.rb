# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCases::Identity::Login, type: :model do
  let!(:tenant) { create(:tenant) }
  let!(:user) { create(:user, tenant: tenant, password: "SecurePassword123!", password_confirmation: "SecurePassword123!", otp_required_for_login: true) }
  let(:fingerprint) { "trusted_fingerprint_abc" }
  let(:digest) { Digest::SHA256.hexdigest(fingerprint) }

  let!(:trusted_device) do
    user.trusted_devices.create!(
      tenant: tenant,
      device_fingerprint_digest: digest,
      last_verified_at: Time.current
    )
  end

  before do
    ActsAsTenant.current_tenant = tenant
    System::Current.ip_address = "192.168.1.50"
    System::Current.user_agent = "Mozilla/5.0"
    user.sessions.create!(
      tenant: tenant,
      expires_at: 24.hours.from_now,
      created_at: 5.days.ago
    )
  end

  after do
    ActsAsTenant.current_tenant = nil
    System::Current.ip_address = nil
    System::Current.user_agent = nil
  end

  describe "#execute" do
    context "with a trusted device and known safe IP" do
      it "bypasses MFA and logs in successfully" do
        result = described_class.new.execute(
          email: user.email,
          password: "SecurePassword123!",
          tenant: tenant,
          ip_address: "192.168.1.50",
          user_agent: "Mozilla/5.0",
          trusted_device_fingerprint: fingerprint
        )

        expect(result).to be_success
        expect(result.meta[:status]).to eq(:success)
        expect(result.meta[:session]).to be_present
      end
    end

    context "with a trusted device but from a new/unseen IP (risky login)" do
      it "forces step-up MFA and logs login_risk_detected audit event" do
        # Expect audit logger to log the risk detection
        expect(Services::System::AuditLogger).to receive(:log).with(
          action: "login_risk_detected",
          auditable: user,
          tenant: tenant,
          metadata: hash_including(ip_address: "10.0.0.1")
        ).and_call_original

        result = described_class.new.execute(
          email: user.email,
          password: "SecurePassword123!",
          tenant: tenant,
          ip_address: "10.0.0.1",
          user_agent: "Mozilla/5.0",
          trusted_device_fingerprint: fingerprint
        )

        expect(result).to be_success
        expect(result.meta[:status]).to eq(:mfa_required)
        expect(result.meta[:session]).to be_nil
      end
    end
  end
end
