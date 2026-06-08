# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require_relative "coverage_helper"

# Set default environment for tests
ENV["RAILS_ENV"] = "test"

# Load the Rails application and its environment
require_relative "../config/environment"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

# Load Clean Architecture components
require_relative "clean_architecture_helper"

# Load support files
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Shoulda Matchers configuration. See https://github.com/thoughtbot/shoulda-matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  # Use the built-in test framework's transaction methods
  config.use_transactional_fixtures = true

  # Infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!
end
