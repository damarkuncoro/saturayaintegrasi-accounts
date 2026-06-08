# frozen_string_literal: true

# This file is used by RSpec to load the Rails environment and
# configure RSpec to work with Rails.

ENV["RAILS_ENV"] = "test"
ENV["DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL"] = "true"

require_relative "coverage_helper"

if ENV["DATABASE_URL"] && ENV["RAILS_ENV"] == "test"
  require "uri"
  begin
    uri = URI.parse(ENV["DATABASE_URL"])
    uri.path = "/satu_raya_test"
    ENV["DATABASE_URL"] = uri.to_s
  rescue URI::InvalidURIError
    ENV["DATABASE_URL"] = ENV["DATABASE_URL"].sub(/\/[^\/]+$/, "/satu_raya_test")
  end
end

require_relative "../config/environment"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Load support files
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# RSpec Rails configuration
require "rspec/rails"

# Add additional requires below this line. Rails is not loaded until this point!

require "shoulda/matchers"
require "database_cleaner/active_record"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true, allow: ["standardization-api:3000", "standardization-api"])

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # Set the fixture paths for request and other specs
  config.fixture_paths = [ Rails.root.join('spec/fixtures') ]

  # Use the built-in test framework's transaction methods
  config.use_transactional_fixtures = true

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Include custom helpers
  config.include RSpec::Rails::RequestExampleGroup, type: :request

  # Clean the database before the suite runs
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  # Setup ActiveJob test helper and force test adapter
  config.include ActiveJob::TestHelper
  config.before(:each) do
    ActsAsTenant.current_tenant = nil
    ActiveJob::Base.queue_adapter = :test
    Searchkick.disable_callbacks if defined?(Searchkick)
  end

  config.after(:each) do
    ActsAsTenant.current_tenant = nil
  end

  config.openapi_root = Rails.root.join('public', 'api-docs')
  config.openapi_format = :yaml

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Satu Kerja API V1',
        version: 'v1',
        description: 'REST API documentation for the Satu Kerja platform. All authenticated API endpoints require a valid JWT token.'
      },
      paths: {},
      servers: [
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: SatuRayaIdentityClient::Identity::BrandConfig.app_domain
            }
          }
        },
        {
          url: 'http://localhost:3000'
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT,
            description: 'Insert JWT token in format: Bearer <token>'
          },
          partner_key: {
            type: :apiKey,
            name: 'X-System::Partner-Key',
            in: :header,
            description: 'API Key for System::Partner Portal'
          }
        }
      }
    }
  }

  config.rswag_dry_run = false
end
