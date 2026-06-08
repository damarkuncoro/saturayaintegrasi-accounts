require "rails_helper"

RSpec.describe Identity::TrustedDevice, type: :model do
  subject { build(:trusted_device) }

  describe "associations" do
    it { should belong_to(:user).class_name("Identity::User") }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it { should validate_presence_of(:device_fingerprint) }
    it { should validate_presence_of(:last_verified_at) }

    it "validates inclusion of revoked in [true, false]" do
      subject.revoked = nil
      expect(subject).not_to be_valid
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns active trusted devices that are not revoked" do
        active_device = create(:trusted_device)
        revoked_device = create(:trusted_device, :revoked)

        expect(described_class.active).to include(active_device)
        expect(described_class.active).not_to include(revoked_device)
      end
    end
  end

  describe "#revoke!" do
    it "sets revoked to true" do
      device = create(:trusted_device)
      expect(device.revoked).to be false

      device.revoke!
      expect(device.revoked).to be true
    end
  end
end
