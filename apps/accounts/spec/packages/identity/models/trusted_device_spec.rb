require "rails_helper"

RSpec.describe Identity::TrustedDevice, type: :model do
  subject { build(:trusted_device, user: create(:user)) }

  describe "associations" do
    it { should belong_to(:user).class_name("Identity::User") }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it { should validate_presence_of(:device_fingerprint_digest) }

    it "defaults last_verified_at to current time" do
      device = Identity::TrustedDevice.new
      device.valid?
      expect(device.last_verified_at).to be_present
    end

    it "is invalid if user belongs to a different tenant" do
      other_tenant = create(:tenant)
      other_user = create(:user, tenant: other_tenant)
      subject.user = other_user
      expect(subject).not_to be_valid
      expect(subject.errors[:user_id]).to include("must belong to the same tenant")
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns active trusted devices that are not revoked" do
        active_device = create(:trusted_device)
        revoked_device = create(:trusted_device, revoked_at: Time.current)

        expect(described_class.active).to include(active_device)
        expect(described_class.active).not_to include(revoked_device)
      end
    end
  end

  describe "#revoke!" do
    it "sets revoked_at to current time" do
      device = create(:trusted_device)
      expect(device.revoked?).to be false

      device.revoke!
      expect(device.revoked?).to be true
      expect(device.revoked_at).to be_present
    end
  end
end
