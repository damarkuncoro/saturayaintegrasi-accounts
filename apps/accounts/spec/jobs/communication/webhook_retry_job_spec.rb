# frozen_string_literal: true

require "rails_helper"

RSpec.describe Communication::WebhookRetryJob, type: :job do
  let!(:tenant) { create(:tenant) }
  let!(:endpoint) do
    ActsAsTenant.with_tenant(tenant) do
      Communication::WebhookEndpoint.create!(
        url: "https://example.com/webhook",
        events: ["user.created"],
        secret: "supersecret",
        active: true
      )
    end
  end

  describe "#perform" do
    let!(:due_delivery) do
      ActsAsTenant.with_tenant(tenant) do
        Communication::WebhookDelivery.create!(
          webhook_endpoint: endpoint,
          event_name: "user.created",
          status: :failed,
          next_retry_at: 1.minute.ago,
          payload: { id: 1 }
        )
      end
    end

    let!(:future_delivery) do
      ActsAsTenant.with_tenant(tenant) do
        Communication::WebhookDelivery.create!(
          webhook_endpoint: endpoint,
          event_name: "user.created",
          status: :failed,
          next_retry_at: 10.minutes.from_now,
          payload: { id: 2 }
        )
      end
    end

    let!(:success_delivery) do
      ActsAsTenant.with_tenant(tenant) do
        Communication::WebhookDelivery.create!(
          webhook_endpoint: endpoint,
          event_name: "user.created",
          status: :success,
          next_retry_at: nil,
          payload: { id: 3 }
        )
      end
    end

    it "enqueues WebhookDeliveryJob only for failed and due deliveries" do
      ActiveJob::Base.queue_adapter = :test

      expect {
        Communication::WebhookRetryJob.perform_now
      }.to have_enqueued_job(Communication::WebhookDeliveryJob).with(
        delivery_id: due_delivery.id,
        endpoint_url: endpoint.url,
        event: "user.created",
        payload: { "id" => 1 }
      ).once
    end
  end
end
