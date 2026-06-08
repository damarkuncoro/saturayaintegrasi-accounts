require "rails_helper"
require "webmock/rspec"

RSpec.describe Identity::UserSyncJob, type: :job do
  let(:payload) { { "action" => "create", "user" => { "id" => "user-123", "email" => "test@example.com" } } }
  let(:secret) { "development_sync_secret_key_123" }

  describe "#perform" do
    before do
      stub_request(:post, "http://app:3000/api/internal/users/sync")
        .to_return(status: 200, body: { status: "success" }.to_json, headers: {})
    end

    it "sends an HTTP POST request with valid X-Satu-Raya-Signature header" do
      described_class.new.perform(payload)

      expected_signature = SatuRayaCommons::Security::HmacSigner.sign(payload.to_json, secret)

      expect(WebMock).to have_requested(:post, "http://app:3000/api/internal/users/sync")
        .with(
          body: payload.to_json,
          headers: {
            "Content-Type" => "application/json",
            "X-Satu-Raya-Signature" => expected_signature
          }
        ).once
    end
  end
end
