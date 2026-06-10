require "rails_helper"

RSpec.describe Identity::Session, type: :model do
  subject { build(:session) }

  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it "is valid when tenant matches user's tenant" do
      tenant = create(:tenant)
      user = create(:user, tenant: tenant)
      session = build(:session, tenant: tenant, user: user)
      expect(session).to be_valid
    end

    it "is invalid when tenant does not match user's tenant" do
      tenant_a = create(:tenant)
      tenant_b = create(:tenant)
      user = create(:user, tenant: tenant_b)

      # We bypass tenant auto-assignment in before_validation by explicitly setting tenant
      session = build(:session, tenant: tenant_a, user: user)
      expect(session).not_to be_valid
      expect(session.errors[:user_id]).to include("must belong to the same tenant")
    end
  end

  describe "before_create callback" do
    it "sets user_agent from System::Current" do
      System::Current.user_agent = "TestAgent/1.0"
      session = create(:session)
      expect(session.user_agent).to eq("TestAgent/1.0")
    end

    it "sets ip_address from System::Current" do
      System::Current.ip_address = "127.0.0.1"
      session = create(:session)
      expect(session.ip_address).to eq("127.0.0.1")
    end
  end
end
