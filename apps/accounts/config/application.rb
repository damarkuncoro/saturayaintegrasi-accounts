require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Explicitly load Core::Result PORO as it is nested under Core module
# but lives in the app/core/ autoload root.
# require_relative "../app/core/result"

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Set default locale and timezone from environment variables or defaults
    config.i18n.default_locale = ENV.fetch("DEFAULT_LOCALE", "id").to_sym
    config.i18n.available_locales = [ :id, :en ]
    config.time_zone = ENV.fetch("TIME_ZONE", "Jakarta")

    # Use Sidekiq for Active job
    config.active_job.queue_adapter = :solid_queue

    # Use UUID for primary keys by default
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Standardized logging from satu-raya-commons
    config.after_initialize do
      SatuRayaCommons::Logging.setup(config)
    end
  end
end
