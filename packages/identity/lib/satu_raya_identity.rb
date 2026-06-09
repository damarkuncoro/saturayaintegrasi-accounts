# frozen_string_literal: true

require "satu_raya_identity/engine"
require "rotp"
require "rqrcode"
require "jwt"

module SatuRayaIdentity
  class << self
    attr_writer :user_sync_publisher

    def user_sync_publisher
      @user_sync_publisher ||= default_user_sync_publisher
    end

    private

    def default_user_sync_publisher
      if defined?(::UseCases::PublishUserSyncEvent)
        ::UseCases::PublishUserSyncEvent.new
      else
        Object.new.tap do |o|
          def o.call(action:, user:)
            Rails.logger.info("[SatuRayaIdentity] Skipped syncing user: no publisher configured.")
          end
        end
      end
    end
  end
end
