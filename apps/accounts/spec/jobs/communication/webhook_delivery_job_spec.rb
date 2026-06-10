# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe Communication::WebhookDeliveryJob, type: :job do
  let!(:tenant) { create(:tenant) }
  let!(:endpoint) do
    ActsAsTenant.with_tenant(tenant) do
      Communication::WebhookEndpoint.create!(
        url: "https://example.com/webhook",
        events: [ "user.created" ],
        secret: "supersecret",
        active: true
      )
    end
  end

  let!(:delivery) do
    ActsAsTenant.with_tenant(tenant) do
      Communication::WebhookDelivery.create!(
        webhook_endpoint: endpoint,
        event_name: "user.created",
        status: :failed,
        payload: { id: 1 }
      )
    end
  end

  describe "#perform" do
    it "sets ActsAsTenant.current_tenant to the delivery's tenant during execution" do
      ActsAsTenant.current_tenant = nil

      stub_request(:post, "https://example.com/webhook").to_return(lambda { |request|
        expect(ActsAsTenant.current_tenant).to eq(tenant)
        { status: 200, body: "success" }
      })

      described_class.new.perform(
        delivery_id: delivery.id,
        endpoint_url: endpoint.url,
        event: "user.created",
        payload: { id: 1 }
      )

      ActsAsTenant.with_tenant(tenant) do
        delivery.reload
        expect(delivery.status).to eq("success")
        expect(delivery.response_code).to eq(200)
        expect(delivery.response_body).to eq("success")
      end
    end

    it "handles failure and sets next_retry_at inside tenant context" do
      ActsAsTenant.current_tenant = nil

      stub_request(:post, "https://example.com/webhook").to_return(lambda { |request|
        expect(ActsAsTenant.current_tenant).to eq(tenant)
        { status: 500, body: "error" }
      })

      expect {
        described_class.new.perform(
          delivery_id: delivery.id,
          endpoint_url: endpoint.url,
          event: "user.created",
          payload: { id: 1 }
        )
      }.to raise_error(StandardError, /Webhook delivery failed with status 500/)

      ActsAsTenant.with_tenant(tenant) do
        delivery.reload
        expect(delivery.status).to eq("failed")
        expect(delivery.response_code).to eq(500)
        expect(delivery.next_retry_at).not_to be_nil
      end
    end
  end
end
