require "rails_helper"

RSpec.describe Identity::SsoClientConfiguration, type: :model do
  subject { build(:sso_client_configuration) }

  describe "associations" do
    it { should belong_to(:tenant).class_name("System::Tenant") }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it { should validate_presence_of(:client_name) }

    it "validates uniqueness of client_id" do
      create(:sso_client_configuration, client_id: "client_id_test")
      new_client = build(:sso_client_configuration, client_id: "client_id_test")
      expect(new_client).not_to be_valid
    end

    it "validates presence of redirect_uris" do
      subject.redirect_uris = nil
      expect(subject).not_to be_valid
    end

    it "validates format of redirect_uris" do
      subject.redirect_uris = [ "invalid-uri" ]
      expect(subject).not_to be_valid
      # The error message from URI.parse("invalid-uri") with our custom validation
      expect(subject.errors[:redirect_uris].to_sentence).to match(/harus menggunakan HTTPS|mengandung URI tanpa host/)
    end

    it "validates presence of allowed_scopes" do
      subject.allowed_scopes = nil
      expect(subject).not_to be_valid
    end

    it "validates inclusion of active in [true, false]" do
      subject.active = nil
      expect(subject).not_to be_valid
    end
  end

  describe "callbacks" do
    it "generates client_id and client_secret on create if blank" do
      config = build(:sso_client_configuration, client_id: nil, client_secret: nil)
      expect(config.client_id).to be_nil
      expect(config.client_secret).to be_nil

      config.save!
      expect(config.client_id).to start_with("client_")
      expect(config.client_secret_digest).to be_present
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns active configurations" do
        active_config = create(:sso_client_configuration)
        inactive_config = create(:sso_client_configuration, :inactive)

        expect(described_class.active).to include(active_config)
        expect(described_class.active).not_to include(inactive_config)
      end
    end
  end

  describe "has_secure_password" do
    it "authenticates client_secret correctly" do
      config = create(:sso_client_configuration, client_secret: "my_secure_secret_123")
      expect(config.authenticate_client_secret("my_secure_secret_123")).to eq(config)
      expect(config.authenticate_client_secret("wrong_secret")).to be false
    end
  end
end
