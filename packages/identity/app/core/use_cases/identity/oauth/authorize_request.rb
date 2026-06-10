# frozen_string_literal: true

module UseCases
  module Identity
    module Oauth
      class AuthorizeRequest < ::Core::BaseUseCase
        attr_reader :params, :session, :current_user

        def initialize(params:, session:, current_user:)
          @params = params
          @session = session
          @current_user = current_user
        end

        # Mengeksekusi proses inisiasi otorisasi.
        # @return [Core::Result]
        def execute
          client = ::Identity::SsoClientConfiguration.active.find_by(client_id: params[:client_id])
          return failure("invalid_client", meta: { status: :bad_request }) if client.nil?

          # Validasi redirect_uri
          unless client.redirect_uris.include?(params[:redirect_uri])
            return failure("invalid_redirect_uri", meta: { status: :bad_request })
          end

          # Simpan params ke session untuk digunakan setelah login
          session[:oauth_params] = params.to_unsafe_h

          # Jika belum login, beri tahu controller untuk redirect
          if current_user.nil?
            return failure("unauthenticated", meta: { status: :unauthorized })
          end

          # Cek apakah user sudah memberikan persetujuan sebelumnya
          existing_consent = ::Identity::UserConsent.find_by(
            user: current_user,
            sso_client_configuration: client,
            revoked_at: nil
          )

          if existing_consent || params[:prompt] == "none"
            code = issue_code(client)
            return success({
              action: :redirect,
              url: "#{params[:redirect_uri]}?code=#{code}&state=#{params[:state]}"
            }, meta: { status: :found })
          end

          success({ action: :render_consent, client: client }, meta: { status: :ok })
        end

        private

        def issue_code(client)
          code = SecureRandom.hex(16)
          Rails.cache.write("oauth_code_#{code}", {
            user_id: current_user.id,
            client_id: client.client_id,
            scopes: params["scope"],
            redirect_uri: params["redirect_uri"],
            code_challenge: params["code_challenge"],
            code_challenge_method: params["code_challenge_method"]
          }, expires_in: 5.minutes)
          code
        end
      end
    end
  end
end
