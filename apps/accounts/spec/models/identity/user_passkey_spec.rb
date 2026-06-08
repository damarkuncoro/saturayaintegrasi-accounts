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
    it { should validate_uniqueness_of(:external_id) }
    it { should validate_presence_of(:public_key) }
    it { should validate_presence_of(:sign_count) }
    it { should validate_numericality_of(:sign_count).is_greater_than_or_equal_to(0) }
    it { should validate_length_of(:nickname).is_at_most(100) }
  end
end
