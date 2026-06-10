# frozen_string_literal: true

require "rails_helper"

RSpec.describe Identity::MfaBackupCode, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  describe "validations" do
    it "is valid with matching user tenant" do
      backup_code = Identity::MfaBackupCode.new(user: user, tenant: tenant, code_digest: "digest")
      expect(backup_code).to be_valid
    end

    it "automatically sets tenant from user" do
      backup_code = Identity::MfaBackupCode.new(user: user, code_digest: "digest")
      backup_code.valid?
      expect(backup_code.tenant).to eq(tenant)
    end

    it "is invalid if user and backup code belong to different tenants" do
      other_tenant = create(:tenant)
      backup_code = Identity::MfaBackupCode.new(user: user, tenant: other_tenant, code_digest: "digest")
      expect(backup_code).not_to be_valid
      expect(backup_code.errors[:user_id]).to include("must belong to the same tenant")
    end
  end
end
