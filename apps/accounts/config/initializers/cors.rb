# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require "satu_raya_identity_client/identity/brand_config"

# Define allowed origins for CORS
# For development, allow localhost
# For production, set via environment variable
domain = SatuRayaIdentityClient::Identity::BrandConfig.app_domain
allowed_origins = if Rails.env.production?
                    ENV.fetch("CORS_ALLOWED_ORIGINS", ENV.fetch("ALLOWED_ORIGINS", "https://#{domain}")).split(",")
                  else
                    [ "http://localhost:3000", "http://localhost:3001", "http://localhost:3002", "http://127.0.0.1:3000" ]
                  end

domain_regex = /https?:\/\/.*\.#{Regexp.escape(domain)}/

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins *allowed_origins, domain_regex
    resource "/api/*",
             headers: :any,
             expose: [ "Authorization", "Content-Type" ],
             methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
             max_age: 600
  end

  # Allow credentials for session-based auth
  allow do
    origins *allowed_origins, domain_regex
    resource "*",
             headers: :any,
             methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
             max_age: 600
  end
end
