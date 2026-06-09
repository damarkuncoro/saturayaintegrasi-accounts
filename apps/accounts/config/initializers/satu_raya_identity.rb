# frozen_string_literal: true

Rails.application.config.to_prepare do
  # 1. Configure user_sync_publisher to delegate to EventBus (decoupling package from specific host classes)
  SatuRayaIdentity.user_sync_publisher = Object.new.tap do |o|
    def o.call(action:, user:)
      event_name = action == "created" ? "identity.user_created" : "identity.user_updated"
      SatuRayaCommons::EventBus.publish(event_name, user_id: user.id, sync_action: action)
    end
  end

  # 2. Subscribe EventBus events to run the actual user sync use case
  SatuRayaCommons::EventBus.subscribe("identity.user_created") do |payload, meta|
    user = ::Identity::User.find_by(id: payload[:user_id])
    if user
      UseCases::PublishUserSyncEvent.new.call(action: "created", user: user)
    end
  end

  SatuRayaCommons::EventBus.subscribe("identity.user_updated") do |payload, meta|
    user = ::Identity::User.find_by(id: payload[:user_id])
    if user
      action = payload[:sync_action] || "updated"
      UseCases::PublishUserSyncEvent.new.call(action: action, user: user)
    end
  end
end
