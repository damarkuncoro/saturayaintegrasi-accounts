module Identity
  class DiscoveryController < ApplicationController
    allow_unauthenticated_access
    skip_before_action :resume_session
    skip_before_action :assign_current_tenant
    skip_before_action :require_current_tenant!, raise: false

    def openid_configuration
      issuer = brand_config.oidc_issuer

      render json: {
        issuer: issuer,
        authorization_endpoint: "#{issuer}/oauth/authorize",
        token_endpoint: "#{issuer}/oauth/token",
        userinfo_endpoint: "#{issuer}/oauth/userinfo",
        revocation_endpoint: "#{issuer}/oauth/revoke",
        jwks_uri: "#{issuer}/.well-known/jwks.json",
        response_types_supported: [ "code", "token", "id_token" ],
        subject_types_supported: [ "public" ],
        id_token_signing_alg_values_supported: [ "RS256" ],
        scopes_supported: [ "openid", "profile", "email" ],
        token_endpoint_auth_methods_supported: [ "client_secret_post", "client_secret_basic" ],
        code_challenge_methods_supported: [ "plain", "S256" ],
        claims_supported: [ "sub", "iss", "auth_time", "name", "given_name", "family_name", "email" ]
      }
    end

    def jwks
      render json: { keys: [ Identity::OauthController.jwk ] }
    end
  end
end
