require "rails_helper"

RSpec.describe Identity::Session, type: :model do
  subject { build(:session) }

  describe "associations" do
    it { should belong_to(:user) }
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
