# frozen_string_literal: true

module Identity
  class OauthController < ApplicationController
    skip_before_action :require_authentication, only: [ :authorize, :consent, :token, :userinfo, :revoke, :introspect ]
    skip_forgery_protection only: [ :token, :revoke, :introspect ]

    # GET /oauth/authorize
    def authorize
      result = UseCases::Identity::Oauth::AuthorizeRequest.new(
        params: params,
        session: session,
        current_user: current_user
      ).execute

      if result.failure?
        if result.error == "unauthenticated"
          return redirect_to sign_in_path(return_to: request.fullpath), allow_other_host: true
        end
        return render json: { error: result.error }, status: result.meta[:status]
      end

      if result.value[:action] == :redirect
        redirect_to result.value[:url], allow_other_host: true
      else
        @client = result.value[:client]
        render :authorize
      end
    end

    # POST /oauth/authorize/consent
    def consent
      result = UseCases::Identity::Oauth::GrantConsent.new(
        params: params,
        session: session,
        current_user: current_user
      ).execute

      if result.failure?
        if result.error == "unauthenticated"
          return redirect_to sign_in_path(return_to: request.fullpath), allow_other_host: true
        end
        return render json: { error: result.error }, status: result.meta[:status]
      end

      redirect_to result.value[:url], allow_other_host: true
    end

    # POST /oauth/token
    def token
      result = UseCases::Identity::Oauth::ExchangeToken.new(
        params: params,
        request: request,
        issuer: brand_config.oidc_issuer
      ).execute

      handle_result(result)
    end

    # GET /oauth/userinfo
    def userinfo
      result = UseCases::Identity::Oauth::GetUserInfo.new(
        request: request
      ).execute
      handle_result(result)
    end

    # POST /oauth/revoke
    def revoke
      result = UseCases::Identity::Oauth::RevokeToken.new(params: params).execute
      handle_result(result)
    end

    # POST /oauth/introspect
    def introspect
      result = UseCases::Identity::Oauth::IntrospectToken.new(
        params: params,
        request: request
      ).execute
      handle_result(result)
    end

    private

    def handle_result(result)
      if result.success?
        render json: result.value, status: result.meta[:status] || :ok
      else
        render json: {
          error: result.error,
          error_description: result.meta[:error_description]
        }.compact, status: result.meta[:status] || :bad_request
      end
    end

    def extract_client_id_from_header
      auth_header = request.headers["Authorization"]
      return nil unless auth_header&.start_with?("Basic ")

      encoded = auth_header.sub("Basic ", "")
      decoded = Base64.decode64(encoded)
      decoded.split(":").first
    rescue StandardError
      nil
    end
  end
end
