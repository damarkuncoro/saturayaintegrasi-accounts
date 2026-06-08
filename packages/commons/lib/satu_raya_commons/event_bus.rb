module SatuRayaCommons
  class EventBus
    # Publishes an event to the system
    # @param event_name [String] Name of the event (e.g., 'user.created')
    # @param payload [Hash] Data associated with the event
    def self.publish(event_name, payload = {})
      full_payload = {
        event: event_name,
        payload: payload,
        meta: {
          timestamp: Time.current,
          tenant_id: ActsAsTenant.current_tenant&.id,
          origin_service: Rails.application.class.module_parent_name.downcase
        }
      }

      # In a real scale-up, this would send to RabbitMQ/Kafka/Redis
      # For now, we use SolidQueue to handle it asynchronously
      SatuRayaCommons::Events::ProcessEventJob.perform_later(full_payload)
      
      Rails.logger.info("[EventBus] Published: #{event_name} from #{full_payload[:meta][:origin_service]}")
    end
  end
end
