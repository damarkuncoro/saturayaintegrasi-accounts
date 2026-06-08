# frozen_string_literal: true

require 'rails_helper'
require 'rswag/specs'

RSpec.configure do |config|
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
end
