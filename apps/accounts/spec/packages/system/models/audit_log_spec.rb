require "rails_helper"

RSpec.describe System::AuditLog, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }

  describe "validations" do
    it "is valid when tenant matches user's tenant" do
      log = System::AuditLog.new(
        tenant: tenant,
        user: user,
        action: "login"
      )
      expect(log).to be_valid
    end

    it "is invalid when user belongs to a different tenant" do
      other_tenant = create(:tenant)
      other_user = create(:user, tenant: other_tenant)

      log = System::AuditLog.new(
        tenant: tenant,
        user: other_user,
        action: "login"
      )
      expect(log).not_to be_valid
      expect(log.errors[:user_id]).to include("must belong to the same tenant")
    end
  end
end
