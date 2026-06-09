module SatuRayaCommons
  class EventBus
    class << self
      def subscribe(event_name, subscriber = nil, &block)
        subscribers[event_name.to_s] ||= []
        subscribers[event_name.to_s] << (subscriber || block)
      end

      def subscribers
        @subscribers ||= {}
      end

      # Publishes an event to the system
      # @param event_name [String] Name of the event (e.g., 'user.created')
      # @param payload [Hash] Data associated with the event
      def publish(event_name, payload = {})
        full_payload = {
          event: event_name.to_s,
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

      def dispatch(event_name, payload, meta)
        handlers = subscribers[event_name.to_s] || []
        handlers.each do |handler|
          if handler.respond_to?(:call)
            handler.call(payload, meta)
          else
            Rails.logger.warn("[EventBus] Subscriber for #{event_name} is not callable.")
          end
        end
      end
    end
  end
end
