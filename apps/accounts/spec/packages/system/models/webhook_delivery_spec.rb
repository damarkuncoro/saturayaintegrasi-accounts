require "rails_helper"

RSpec.describe Communication::WebhookDelivery, type: :model do
  let(:tenant) { create(:tenant) }
  let(:webhook_endpoint) do
    Communication::WebhookEndpoint.create!(
      tenant: tenant,
      url: "https://example.com/webhook",
      events: ["user.created"],
      secret: "supersecret"
    )
  end

  describe "validations" do
    it "is valid when tenant matches webhook_endpoint's tenant" do
      delivery = Communication::WebhookDelivery.new(
        tenant: tenant,
        webhook_endpoint: webhook_endpoint,
        event_name: "user.created",
        status: :pending
      )
      expect(delivery).to be_valid
    end

    it "is invalid when webhook_endpoint belongs to a different tenant" do
      other_tenant = create(:tenant)
      other_endpoint = Communication::WebhookEndpoint.create!(
        tenant: other_tenant,
        url: "https://example.com/webhook",
        events: ["user.created"],
        secret: "supersecret"
      )

      delivery = Communication::WebhookDelivery.new(
        tenant: tenant,
        webhook_endpoint: other_endpoint,
        event_name: "user.created",
        status: :pending
      )
      expect(delivery).not_to be_valid
      expect(delivery.errors[:webhook_endpoint_id]).to include("must belong to the same tenant")
    end

    it "sets tenant automatically from webhook_endpoint on validation if tenant is not present" do
      delivery = Communication::WebhookDelivery.new(
        webhook_endpoint: webhook_endpoint,
        event_name: "user.created",
        status: :pending
      )
      expect(delivery).to be_valid
      expect(delivery.tenant_id).to eq(tenant.id)
    end
  end
end
