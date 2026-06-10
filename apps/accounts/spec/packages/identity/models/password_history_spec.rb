# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity::PasswordHistory, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  describe "validations" do
    it "is valid with matching user tenant" do
      history = Identity::PasswordHistory.new(user: user, tenant: tenant, password_digest: "digest")
      expect(history).to be_valid
    end

    it "automatically sets tenant from user" do
      history = Identity::PasswordHistory.new(user: user, password_digest: "digest")
      history.valid?
      expect(history.tenant).to eq(tenant)
    end

    it "is invalid if user and password history belong to different tenants" do
      other_tenant = create(:tenant)
      history = Identity::PasswordHistory.new(user: user, tenant: other_tenant, password_digest: "digest")
      expect(history).not_to be_valid
      expect(history.errors[:user_id]).to include("must belong to the same tenant")
    end
  end
end
