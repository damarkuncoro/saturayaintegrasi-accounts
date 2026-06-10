# frozen_string_literal: true

require "rails_helper"

RSpec.describe UseCases::Identity::Mfa::VerifyChallenge do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:mfa_service) { instance_double(Identity::MfaService) }
  let(:use_case) { described_class.new(service: mfa_service) }

  before do
    user.enable_2fa!
    # Set active tenant
    ActsAsTenant.current_tenant = tenant
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe "#execute" do
    context "when the user is already locked" do
      before do
        user.lock!
      end

      it "returns failure immediately without checking the OTP code" do
        expect(mfa_service).not_to receive(:verify_login_code)

        result = use_case.execute(user: user, otp_code: "123456", tenant: tenant)

        expect(result).not_to be_success
        expect(result.error).to eq("Akun Anda sedang terkunci. Silakan hubungi admin atau reset kata sandi.")
      end
    end

    context "when the OTP code is valid" do
      let(:session) { instance_double(Identity::Session, id: SecureRandom.uuid) }

      before do
        allow(mfa_service).to receive(:verify_login_code)
          .with(user: user, code: "123456", tenant: tenant)
          .and_return(Core::Result.success(:totp))

        # Mock session creation to prevent actual database write if preferred,
        # but let's allow actual DB creation or mock it.
        # Since we have database cleaner / transactional tests, actual DB creation is fine.
        user.update!(failed_attempts: 3)
      end

      it "resets failed attempts, creates a session, and returns success" do
        result = use_case.execute(user: user, otp_code: "123456", tenant: tenant)

        expect(result).to be_success
        expect(user.reload.failed_attempts).to eq(0)
        expect(Identity::Session.count).to eq(1)
      end
    end

    context "when the OTP code is invalid" do
      before do
        allow(mfa_service).to receive(:verify_login_code)
          .with(user: user, code: "wrong_code", tenant: tenant)
          .and_return(Core::Result.failure("Kode MFA tidak valid."))
      end

      it "increments the failed attempts counter" do
        expect {
          use_case.execute(user: user, otp_code: "wrong_code", tenant: tenant)
        }.to change { user.reload.failed_attempts }.by(1)
      end

      it "does not lock the account if attempts are under 5" do
        use_case.execute(user: user, otp_code: "wrong_code", tenant: tenant)
        expect(user.reload).not_to be_locked
      end

      it "locks the account and logs audit when attempts reach 5" do
        user.update!(failed_attempts: 4)

        result = nil
        expect {
          result = use_case.execute(user: user, otp_code: "wrong_code", tenant: tenant)
        }.to change { System::AuditLog.count }.by(2)

        expect(user.reload).to be_locked
        expect(result).not_to be_success
        expect(result.error).to eq("Akun Anda sedang terkunci. Silakan hubungi admin atau reset kata sandi.")

        audit_actions = System::AuditLog.order(created_at: :asc).last(2).map(&:action)
        expect(audit_actions).to contain_exactly("account_locked", "mfa_login_failed")
        expect(System::AuditLog.last.auditable_id).to eq(user.id)
      end
    end
  end
end
