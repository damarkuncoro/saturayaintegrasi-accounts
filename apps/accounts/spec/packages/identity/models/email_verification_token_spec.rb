# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity::EmailVerificationToken, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  describe "validations" do
    it "is valid with matching user tenant" do
      token = Identity::EmailVerificationToken.new(user: user, tenant: tenant, token_digest: "digest", expires_at: 1.day.from_now)
      expect(token).to be_valid
    end

    it "automatically sets tenant from user" do
      token = Identity::EmailVerificationToken.new(user: user, token_digest: "digest", expires_at: 1.day.from_now)
      token.valid?
      expect(token.tenant).to eq(tenant)
    end

    it "is invalid if user and email verification token belong to different tenants" do
      other_tenant = create(:tenant)
      token = Identity::EmailVerificationToken.new(user: user, tenant: other_tenant, token_digest: "digest", expires_at: 1.day.from_now)
      expect(token).not_to be_valid
      expect(token.errors[:user_id]).to include("must belong to the same tenant")
    end
  end
end
