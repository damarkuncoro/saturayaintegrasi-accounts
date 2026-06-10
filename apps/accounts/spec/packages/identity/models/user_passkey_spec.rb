require "rails_helper"

RSpec.describe Identity::UserPasskey, type: :model do
  subject { build(:user_passkey) }

  describe "associations" do
    it { should belong_to(:user).class_name("Identity::User") }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it { should validate_presence_of(:external_id) }

    it "validates uniqueness of external_id scoped to tenant_id" do
      passkey = create(:user_passkey)
      duplicate = build(:user_passkey, external_id: passkey.external_id, tenant: passkey.tenant)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_id]).to include("sudah digunakan")
    end

    it { should validate_presence_of(:public_key) }
    it { should validate_presence_of(:sign_count) }
    it { should validate_numericality_of(:sign_count).is_greater_than_or_equal_to(0) }
    it { should validate_length_of(:nickname).is_at_most(100) }

    it "validates that user and passkey belong to the same tenant" do
      other_tenant = create(:tenant)
      passkey = build(:user_passkey)
      passkey.tenant = other_tenant
      expect(passkey).not_to be_valid
      expect(passkey.errors[:user_id]).to include("must belong to the same tenant")
    end
  end
end
