module SatuRayaCommons
  module Events
    class ProcessEventJob < ActiveJob::Base
      queue_as :events

      def perform(event_data)
        event_name = event_data["event"]
        payload = event_data["payload"]
        meta = event_data["meta"]

        # Ensure tenant context is set for the worker
        if meta["tenant_id"]
          tenant = System::Tenant.find(meta["tenant_id"])
          ActsAsTenant.with_tenant(tenant) do
            dispatch_event(event_name, payload, meta)
          end
        else
          dispatch_event(event_name, payload, meta)
        end
      end

      private

      def dispatch_event(name, payload, meta)
        Rails.logger.info("[EventBus] Dispatching #{name} to subscribers...")
        SatuRayaCommons::EventBus.dispatch(name, payload, meta)
      end
    end
  end
end
