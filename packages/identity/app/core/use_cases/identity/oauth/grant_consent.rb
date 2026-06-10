# frozen_string_literal: true

module UseCases
  module Identity
    module Oauth
      class GrantConsent < ::Core::BaseUseCase
        attr_reader :params, :session, :current_user

        def initialize(params:, session:, current_user:)
          @params = params
          @session = session
          @current_user = current_user
        end

        # Mengeksekusi proses pemberian persetujuan user.
        # @return [Core::Result]
        def execute
          client = ::Identity::SsoClientConfiguration.active.find_by(client_id: params[:client_id])
          return failure("invalid_client", meta: { status: :bad_request }) if client.nil?

          if current_user.nil?
            return failure("unauthenticated", meta: { status: :unauthorized })
          end

          if params[:allow] == "true"
            oauth_params = session[:oauth_params] || params
            scopes = (oauth_params["scope"] || "openid profile email").split(" ")
            scopes_hash = scopes.each_with_object({}) { |scope, hash| hash[scope] = true }

            ::Identity::UserConsent.create!(
              user: current_user,
              sso_client_configuration: client,
              consented_scopes: scopes_hash,
              granted_at: Time.current,
              consent_signature: SecureRandom.hex(32)
            )

            code = issue_code(client, oauth_params)
            success({
              action: :redirect,
              url: "#{oauth_params["redirect_uri"]}?code=#{code}&state=#{oauth_params["state"]}"
            }, meta: { status: :found })
          else
            redirect_uri = session.dig(:oauth_params, "redirect_uri") || params[:redirect_uri]
            success({
              action: :redirect,
              url: "#{redirect_uri}?error=access_denied"
            }, meta: { status: :found })
          end
        end

        private

        def issue_code(client, oauth_params)
          code = SecureRandom.hex(16)
          Rails.cache.write("oauth_code_#{code}", {
            user_id: current_user.id,
            client_id: client.client_id,
            scopes: oauth_params["scope"],
            redirect_uri: oauth_params["redirect_uri"],
            code_challenge: oauth_params["code_challenge"],
            code_challenge_method: oauth_params["code_challenge_method"]
          }, expires_in: 5.minutes)
          code
        end
      end
    end
  end
end
