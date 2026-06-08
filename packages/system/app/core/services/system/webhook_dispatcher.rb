module Services
  module System
    class WebhookDispatcher
      def self.dispatch(event_name, tenant_id, payload)
        endpoints = ::Communication::WebhookEndpoint.where(tenant_id: tenant_id, active: true)

        endpoints.each do |endpoint|
          next unless endpoint.events.include?("*") || endpoint.events.include?(event_name)

          # Hitung signature HMAC-SHA256
          timestamp = Time.current.to_i.to_s
          signature_payload = "#{timestamp}.#{payload.to_json}"
          signature = OpenSSL::HMAC.hexdigest("SHA256", endpoint.secret, signature_payload)

          # Create delivery record
          delivery = ::Communication::WebhookDelivery.create!(
            tenant_id: tenant_id,
            webhook_endpoint_id: endpoint.id,
            event_name: event_name,
            payload: payload,
            status: :pending
          )

          # Enqueue background job for delivery
          ::Communication::WebhookDeliveryJob.perform_later(
            delivery_id: delivery.id,
            endpoint_url: endpoint.url,
            event: event_name,
            payload: payload,
            headers: {
              "X-Satu-Raya-Signature" => signature,
              "X-Satu-Raya-Timestamp" => timestamp            }
          )

          Rails.logger.info "[Webhook] Dispatching #{event_name} to #{endpoint.url} with signature verification"
        end
      end
    end
  end
end
