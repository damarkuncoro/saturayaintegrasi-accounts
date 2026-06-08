# frozen_string_literal: true

return unless ENV.fetch("COVERAGE", "true") == "true"
return if defined?(SimpleCov)

require "simplecov"

SimpleCov.start "rails" do
  add_filter "/spec/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/vendor/"

  add_group "Core Use Cases", "app/core/use_cases"
  add_group "Core Services", "app/core/services"
  add_group "Core Repositories", "app/core/repositories"
  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
end
