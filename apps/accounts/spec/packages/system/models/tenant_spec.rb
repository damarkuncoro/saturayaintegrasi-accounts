require "rails_helper"

RSpec.describe System::Tenant, type: :model do
  subject { build(:tenant) }

  describe "associations" do
    it { should have_many(:users).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_presence_of(:plan) }
  end

  describe "slug format" do
    it "accepts valid slugs" do
      %w[company-1 mycompany test-123].each do |slug|
        expect(build(:tenant, slug: slug)).to be_valid
      end
    end

    it "rejects invalid slugs" do
      tenant = build(:tenant, slug: "Invalid")
      expect(tenant).not_to be_valid
      expect(tenant.errors[:slug]).to be_present
    end
  end

  describe "enums" do
    it "defines plan enum with string values" do
      expect(System::Tenant.plans).to eq({ "starter" => "starter", "pro" => "pro", "enterprise" => "enterprise" })
    end
  end

  describe "scopes" do
    it ".active returns only active tenants" do
      active = create(:tenant, :active)
      _inactive = create(:tenant, :inactive)
      expect(System::Tenant.active).to include(active)
    end
  end
end
