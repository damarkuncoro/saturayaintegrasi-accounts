# frozen_string_literal: true

Rails.application.config.to_prepare do
  SatuRayaIdentity.user_sync_publisher = UseCases::PublishUserSyncEvent.new
end
