# frozen_string_literal: true

Rails.application.config.to_prepare do
  # 1. Configure user_sync_publisher to delegate to EventBus (decoupling package from specific host classes)
  SatuRayaIdentity.user_sync_publisher = Object.new.tap do |o|
    def o.execute(action:, user:)
      event_name = action == "created" ? "identity.user_created" : "identity.user_updated"
      SatuRayaCommons::EventBus.publish(event_name, user_id: user.id, sync_action: action)
    end
  end

  # 2. Subscribe EventBus events to run the actual user sync use case
  SatuRayaCommons::EventBus.subscribe("identity.user_created") do |payload, meta|
    user = ::Identity::User.find_by(id: payload[:user_id])
    if user
      UseCases::PublishUserSyncEvent.new.execute(action: "created", user: user)
    end
  end

  SatuRayaCommons::EventBus.subscribe("identity.user_updated") do |payload, meta|
    user = ::Identity::User.find_by(id: payload[:user_id])
    if user
      action = payload[:sync_action] || "updated"
      UseCases::PublishUserSyncEvent.new.execute(action: action, user: user)
    end
  end

  # 3. Subscribe all events to WebhookDispatcher
  SatuRayaCommons::EventBus.subscribe("*") do |payload, meta|
    tenant_id = meta[:tenant_id] || meta["tenant_id"]
    event_name = meta[:event] || meta["event"]

    if tenant_id && event_name
      Services::System::WebhookDispatcher.dispatch(event_name, tenant_id, payload)
    end
  end
end
