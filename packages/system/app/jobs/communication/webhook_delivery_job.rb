module Communication
  class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  retry_on Faraday::Error, wait: :exponentially_longer, attempts: 5

  def perform(delivery_id:, endpoint_url:, event:, payload:, headers: {}, attempt: 1)
    delivery = ::Communication::WebhookDelivery.find(delivery_id)
    delivery.increment!(:attempt_count)
    start_time = Time.current

    response = Faraday.post(endpoint_url) do |req|
      req.headers["Content-Type"] = "application/json"
      req.headers["User-Agent"] = "Satu-Raya-Webhook/1.0"
      headers.each { |k, v| req.headers[k] = v }
      req.body = payload.to_json
    end

    duration = ((Time.current - start_time) * 1000).to_i

    delivery.update!(
      response_code: response.status,
      response_body: response.body.to_s.truncate(1000),
      duration_ms: duration,
      status: response.success? ? :success : :failed,
      delivered_at: response.success? ? Time.current : nil,
      next_retry_at: nil # Clear retry time on success/final state
    )

    unless response.success?
      Rails.logger.error "[Webhook] Failed to deliver #{event} to #{endpoint_url}. Status: #{response.status}"
      raise "Webhook delivery failed with status #{response.status}" if response.status >= 500 || response.status == 429
    end
  rescue => e
    if delivery
      # Estimate next retry wait time (matching ActiveJob's exponentially_longer strategy)
      next_wait = (delivery.attempt_count ** 4) + 15
      delivery.update(
        status: :failed,
        error_message: e.message.truncate(500),
        next_retry_at: delivery.attempt_count < 5 ? Time.current + next_wait.seconds : nil
      )
    end
    Rails.logger.error "[Webhook] Error delivering #{event} to #{endpoint_url}: #{e.message}"
    raise e
  end
end

end