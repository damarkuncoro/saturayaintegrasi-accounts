module Identity
  class DiscoveryController < ApplicationController
    allow_unauthenticated_access
    skip_before_action :resume_session
    skip_before_action :assign_current_tenant

    def openid_configuration
      issuer = brand_config.oidc_issuer
      
      render json: {
        issuer: issuer,
        authorization_endpoint: "#{issuer}/oauth/authorize",
        token_endpoint: "#{issuer}/oauth/token",
        userinfo_endpoint: "#{issuer}/oauth/userinfo",
        revocation_endpoint: "#{issuer}/oauth/revoke",
        jwks_uri: "#{issuer}/.well-known/jwks.json",
        response_types_supported: ["code", "token", "id_token"],
        subject_types_supported: ["public"],
        id_token_signing_alg_values_supported: ["HS256"],
        scopes_supported: ["openid", "profile", "email"],
        token_endpoint_auth_methods_supported: ["client_secret_post", "client_secret_basic"],
        claims_supported: ["sub", "iss", "auth_time", "name", "given_name", "family_name", "email"]
      }
    end

    def jwks
      # Since we are using HS256 (symmetric), we don't have public keys to expose.
      # However, some OIDC clients might check this endpoint.
      # We return an empty keys array for HS256.
      render json: { keys: [] }
    end
  end
end
