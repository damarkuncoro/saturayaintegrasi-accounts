require "rails_helper"

RSpec.describe Identity::User, type: :model do
  subject { build(:user) }

  describe "associations" do
    it { should belong_to(:tenant) }
    it { should have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    it "is invalid without email" do
      user = build(:user, email: nil)
      user.valid?
      expect(user.errors[:email]).to be_present
    end

    it "is invalid without first_name" do
      user = build(:user, first_name: nil)
      user.valid?
      expect(user.errors[:first_name]).to be_present
    end

    it "requires unique email within tenant" do
      tenant = create(:tenant)
      create(:user, email: "test@example.com", tenant: tenant)
      user2 = build(:user, email: "test@example.com", tenant: tenant)
      user2.valid?
      expect(user2.errors[:email]).to be_present
    end

    it { should validate_length_of(:password).is_at_least(12) }
  end

  describe "enums" do
    it { should define_enum_for(:role).with_values(user: 0, admin: 1, support: 2).backed_by_column_of_type(:integer) }
  end

  describe "normalizations" do
    it "downcases and strips email" do
      user = build(:user, email: "  John@Example.COM  ")
      user.valid?
      expect(user.email).to eq("john@example.com")
    end
  end

  describe "#full_name" do
    it "returns the full name" do
      user = build(:user, first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end

    it "handles missing last name" do
      user = build(:user, first_name: "John", last_name: nil)
      expect(user.full_name).to eq("John")
    end
  end

  describe "username generation" do
    it "generates username from email on create" do
      tenant = create(:tenant)
      user = build(:user, email: "john.doe@example.com", username: nil, tenant: tenant)
      user.save!
      expect(user.username).to start_with("johndoe")
    end

    it "ensures username uniqueness" do
      tenant = create(:tenant)
      create(:user, email: "john@example.com", username: "john", tenant: tenant)
      user2 = build(:user, email: "john@test.com", username: nil, tenant: tenant)
      user2.save!
      expect(user2.username).not_to eq("john")
    end
  end

  describe "email change resets verification" do
    it "sets verified to false when email changes on update" do
      user = create(:user, :with_verified_email, email: "old@example.com")
      user.update!(email: "new@example.com")
      expect(user.reload.verified).to be false
    end
  end

  describe "JWT token" do
    it "generates a valid JWT token" do
      user = create(:user)
      token = user.generate_jwt_token
      expect(token).to be_a(String)
      expect(token.split(".").length).to eq(3)
    end

    it "decodes a valid JWT token" do
      user = create(:user)
      token = user.generate_jwt_token
      decoded = Identity::User.decode_jwt_token(token)
      expect(decoded).to eq(user)
    end

    it "returns nil for invalid token" do
      expect(Identity::User.decode_jwt_token("invalid.token.here")).to be_nil
    end

    it "returns nil for expired token" do
      user = create(:user)
      token = user.generate_jwt_token(expires_in: -1.hour)
      expect(Identity::User.decode_jwt_token(token)).to be_nil
    end
  end

  describe "scopes" do
    it ".active returns only active users" do
      active = create(:user, active: true)
      _inactive = create(:user, :inactive)
      expect(Identity::User.active).to include(active)
    end

    it ".admins returns only admins" do
      admin = create(:user, :admin)
      _user = create(:user)
      expect(Identity::User.admins).to include(admin)
    end
  end
end
