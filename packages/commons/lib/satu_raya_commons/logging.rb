require "lograge"

module SatuRayaCommons
  module Logging
    def self.setup(config)
      # Enable Lograge for structured logging
      config.lograge.enabled = true
      
      # Use JSON in production for better observability, pretty in development
      if Rails.env.production?
        config.lograge.formatter = Lograge::Formatters::Json.new
      else
        config.lograge.formatter = Lograge::Formatters::KeyValue.new
      end

      # Add custom data to logs
      config.lograge.custom_options = lambda do |event|
        {
          time: Time.current,
          tenant_id: ActsAsTenant.current_tenant&.id,
          user_id: System::Current.user&.id,
          remote_ip: event.payload[:remote_ip],
          user_agent: event.payload[:user_agent]
        }.compact
      end
    end
  end
end
