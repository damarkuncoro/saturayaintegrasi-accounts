require "rails_helper"

RSpec.describe Identity::UserConsent, type: :model do
  let(:tenant) { create(:tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:sso_client_configuration) { create(:sso_client_configuration, tenant: tenant) }

  subject { build(:user_consent, user: user, tenant: tenant, sso_client_configuration: sso_client_configuration) }

  describe "associations" do
    it { should belong_to(:user).class_name("Identity::User") }
    it "belongs to a tenant" do
      association = described_class.reflect_on_association(:tenant)

      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq("System::Tenant")
    end

    it { should belong_to(:sso_client_configuration).class_name("Identity::SsoClientConfiguration") }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it { should validate_presence_of(:granted_at) }
    it { should validate_presence_of(:consent_signature) }
    it { should validate_presence_of(:consented_scopes) }

    it "is invalid if consented_scopes is not a Hash" do
      subject.consented_scopes = "not a hash"
      expect(subject).not_to be_valid
      expect(subject.errors[:consented_scopes]).to include("harus bertipe Hash/JSON object")
    end

    it "is invalid if user belongs to a different tenant" do
      other_tenant = create(:tenant)
      other_user = create(:user, tenant: other_tenant)
      subject.user = other_user
      expect(subject).not_to be_valid
      expect(subject.errors[:user_id]).to include("must belong to the same tenant")
    end

    it "is invalid if sso_client_configuration belongs to a different tenant" do
      other_tenant = create(:tenant)
      other_client = create(:sso_client_configuration, tenant: other_tenant)
      subject.sso_client_configuration = other_client
      expect(subject).not_to be_valid
      expect(subject.errors[:sso_client_configuration_id]).to include("must belong to the same tenant")
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns consents that are not revoked" do
        active_consent = create(:user_consent)
        revoked_consent = create(:user_consent, :revoked)

        expect(described_class.active).to include(active_consent)
        expect(described_class.active).not_to include(revoked_consent)
      end
    end
  end

  describe "#revoke!" do
    it "sets revoked_at to current time" do
      consent = create(:user_consent)
      expect(consent.revoked_at).to be_nil

      consent.revoke!
      expect(consent.revoked_at).to be_present
    end
  end
end
