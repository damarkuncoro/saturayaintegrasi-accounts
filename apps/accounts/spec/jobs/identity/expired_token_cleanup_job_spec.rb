# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity::ExpiredTokenCleanupJob, type: :job do
  describe "#perform" do
    let!(:tenant1) { create(:tenant, domain: "tenant1.example.com") }
    let!(:tenant2) { create(:tenant, domain: "tenant2.example.com") }

    let!(:user1) { create(:user, tenant: tenant1) }
    let!(:user2) { create(:user, tenant: tenant2) }

    before do
      # Set up tokens for Tenant 1
      ActsAsTenant.with_tenant(tenant1) do
        user1.email_verification_tokens.create!(
          token_digest: Digest::SHA256.hexdigest("token_active_email_1"),
          expires_at: 1.hour.from_now
        )
        user1.email_verification_tokens.create!(
          token_digest: Digest::SHA256.hexdigest("token_expired_email_1"),
          expires_at: 1.hour.ago
        )
        user1.password_reset_tokens.create!(
          token_digest: Digest::SHA256.hexdigest("token_active_reset_1"),
          expires_at: 1.hour.from_now
        )
        user1.password_reset_tokens.create!(
          token_digest: Digest::SHA256.hexdigest("token_expired_reset_1"),
          expires_at: 1.hour.ago
        )
      end

      # Set up tokens for Tenant 2
      ActsAsTenant.with_tenant(tenant2) do
        user2.email_verification_tokens.create!(
          token_digest: Digest::SHA256.hexdigest("token_active_email_2"),
          expires_at: 2.hours.from_now
        )
        user2.email_verification_tokens.create!(
          token_digest: Digest::SHA256.hexdigest("token_expired_email_2"),
          expires_at: 2.hours.ago
        )
        user2.password_reset_tokens.create!(
          token_digest: Digest::SHA256.hexdigest("token_active_reset_2"),
          expires_at: 2.hours.from_now
        )
        user2.password_reset_tokens.create!(
          token_digest: Digest::SHA256.hexdigest("token_expired_reset_2"),
          expires_at: 2.hours.ago
        )
      end
    end

    it "purges expired email verification and password reset tokens across all tenants" do
      expect {
        described_class.new.perform
      }.to change {
        ActsAsTenant.without_tenant { Identity::EmailVerificationToken.count }
      }.by(-2).and change {
        ActsAsTenant.without_tenant { Identity::PasswordResetToken.count }
      }.by(-2)

      # Verify active tokens remain
      ActsAsTenant.without_tenant do
        expect(Identity::EmailVerificationToken.pluck(:token_digest)).to contain_exactly(
          Digest::SHA256.hexdigest("token_active_email_1"),
          Digest::SHA256.hexdigest("token_active_email_2")
        )
        expect(Identity::PasswordResetToken.pluck(:token_digest)).to contain_exactly(
          Digest::SHA256.hexdigest("token_active_reset_1"),
          Digest::SHA256.hexdigest("token_active_reset_2")
        )
      end
    end
  end
end
