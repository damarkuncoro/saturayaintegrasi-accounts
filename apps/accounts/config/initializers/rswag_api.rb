# frozen_string_literal: true

Rswag::Api.configure do |c|
  # Specify a root folder where Swagger JSON or YAML files are located
  # This is used by the API middleware to serve swagger requests
  c.openapi_root = Rails.root.join("public", "api-docs").to_s
end
