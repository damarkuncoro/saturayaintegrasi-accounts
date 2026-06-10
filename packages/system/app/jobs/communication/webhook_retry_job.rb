# frozen_string_literal: true

module Communication
  class WebhookRetryJob < ApplicationJob
    queue_as :default

    def perform
      ActsAsTenant.without_tenant do
        deliveries = ::Communication::WebhookDelivery.where(status: :failed)
                                                  .where("next_retry_at <= ?", Time.current)

        deliveries.find_each do |delivery|
          # Enqueue job baru untuk mencoba kembali pengiriman
          ::Communication::WebhookDeliveryJob.perform_later(
            delivery_id: delivery.id,
            endpoint_url: delivery.webhook_endpoint.url,
            event: delivery.event_name,
            payload: delivery.payload
          )
        end
      end
    end
  end
end
