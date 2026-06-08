# frozen_string_literal: true

Rswag::Ui.configure do |c|
  # List the Swagger endpoints that you want to be documented through the swagger-ui
  # The first parameter is the path, relative to rswag's root path, where the swagger file will be delivered
  # The second parameter is a title for the toggle option in the header
  c.openapi_endpoint "/api-docs/v1/swagger.yaml", "API V1 Docs"

  # Disable Swagger UI's remote schema validator for local HTTPS.
  # The validator service cannot read satu-raya.dev when it uses Caddy's
  # internal certificate authority, even though the spec is reachable locally.
  c.config_object["validatorUrl"] = nil
end
