# frozen_string_literal: true

module UseCases
  module Identity
    module Oauth
      class ExchangeToken < ::Core::BaseUseCase
        include ClientAuthHelper

        attr_reader :params, :request, :issuer

        def initialize(params:, request:, issuer:)
          @params = params
          @request = request
          @issuer = issuer
        end

        # Mengeksekusi proses pertukaran token berdasarkan grant_type.
        # @return [Core::Result]
        def execute
          case params[:grant_type]
          when "client_credentials"
            handle_client_credentials
          when "refresh_token"
            handle_refresh_token
          when "authorization_code"
            handle_authorization_code
          else
            failure("unsupported_grant_type", meta: { status: :bad_request })
          end
        end

        private

        def handle_client_credentials
          client = find_service_client(params, request)
          if client.nil? || !authenticate_service_client(client, params, request)
            return failure("invalid_client", meta: { status: :unauthorized })
          end

          now = Time.current.to_i
          requested_scopes = params[:scope] ? params[:scope].split(" ") : client.allowed_scopes
          invalid_scopes = requested_scopes - client.allowed_scopes
          if invalid_scopes.any?
            return failure("invalid_scope", meta: { status: :bad_request })
          end

          access_token_payload = {
            iss: issuer,
            sub: client.client_id,
            tenant_id: client.tenant_id.to_s,
            aud: client.client_id,
            exp: 1.hour.from_now.to_i,
            iat: now,
            scopes: requested_scopes.join(" "),
            client_credentials: true
          }

          access_token = JWT.encode(access_token_payload, jwks_manager.rsa_key, "RS256", { kid: jwks_manager.jwk[:kid] })

          success({
            access_token: access_token,
            token_type: "Bearer",
            expires_in: 3600,
            scope: requested_scopes.join(" ")
          }, meta: { status: :ok })
        end

        def handle_refresh_token
          client = find_sso_client(params, request)
          if client.nil? || !authenticate_sso_client(client, params, request)
            return failure("invalid_client", meta: { status: :unauthorized })
          end

          refresh_token_param = params[:refresh_token]
          if refresh_token_param.blank?
            return failure("invalid_grant", meta: { status: :bad_request })
          end

          token_digest = ::Identity::JwtRefreshToken.digest(refresh_token_param)
          refresh_token_record = ::Identity::JwtRefreshToken.find_by(token_digest: token_digest)

          if refresh_token_record.nil?
            return failure("invalid_grant", meta: { status: :bad_request })
          end

          # Replay attack check: if token is already revoked, revoke the whole family
          if refresh_token_record.revoked?
            ::Identity::JwtRefreshToken.where(family_id: refresh_token_record.family_id).update_all(revoked_at: Time.current)
            return failure("invalid_grant", meta: { status: :bad_request })
          end

          if refresh_token_record.expired?
            return failure("invalid_grant", meta: { status: :bad_request })
          end

          if refresh_token_record.sso_client_configuration_id != client.id
            return failure("invalid_grant", meta: { status: :bad_request })
          end

          user = refresh_token_record.user
          if !user.active? || !user.tenant.active?
            return failure("invalid_grant", meta: { status: :bad_request })
          end

          new_refresh_token = "rt_#{SecureRandom.hex(32)}"
          new_digest = ::Identity::JwtRefreshToken.digest(new_refresh_token)

          new_record = nil
          ::Identity::JwtRefreshToken.transaction do
            new_record = ::Identity::JwtRefreshToken.create!(
              tenant: user.tenant,
              user: user,
              sso_client_configuration: client,
              token_digest: new_digest,
              family_id: refresh_token_record.family_id,
              scopes: refresh_token_record.scopes,
              expires_at: 30.days.from_now,
              ip_address: request.ip,
              user_agent: request.user_agent
            )

            refresh_token_record.update!(
              revoked_at: Time.current,
              replaced_by_id: new_record.id
            )
          end

          generate_tokens_response(user, client, new_record.scopes.join(" "), new_refresh_token)
        end

        def handle_authorization_code
          client = find_sso_client(params, request)
          if client.nil? || !authenticate_sso_client(client, params, request)
            return failure("invalid_client", meta: { status: :unauthorized })
          end

          cached_data = Rails.cache.read("oauth_code_#{params[:code]}")

          if cached_data.nil? || cached_data[:client_id] != client.client_id
            return failure("invalid_grant", meta: { status: :bad_request })
          end

          # PKCE verification if challenge is present
          if cached_data[:code_challenge].present?
            code_verifier = params[:code_verifier]
            if code_verifier.blank?
              return failure("invalid_request", meta: { error_description: "code_verifier is required", status: :bad_request })
            end

            challenge_method = cached_data[:code_challenge_method] || "plain"
            if challenge_method == "S256"
              calculated = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).tr("=", "")
            elsif challenge_method == "plain"
              calculated = code_verifier
            else
              return failure("invalid_request", meta: { error_description: "Unsupported code_challenge_method", status: :bad_request })
            end

            if calculated != cached_data[:code_challenge]
              return failure("invalid_grant", meta: { error_description: "PKCE verification failed", status: :bad_request })
            end
          end

          # Hapus code setelah digunakan
          Rails.cache.delete("oauth_code_#{params[:code]}")

          user = ::Identity::User.find(cached_data[:user_id])

          # Generate and store refresh token
          refresh_token = "rt_#{SecureRandom.hex(32)}"
          token_digest = ::Identity::JwtRefreshToken.digest(refresh_token)
          scopes_arr = (cached_data[:scopes] || "openid profile email").split(" ")

          ::Identity::JwtRefreshToken.create!(
            tenant: user.tenant,
            user: user,
            sso_client_configuration: client,
            token_digest: token_digest,
            family_id: SecureRandom.uuid,
            scopes: scopes_arr,
            expires_at: 30.days.from_now,
            ip_address: request.ip,
            user_agent: request.user_agent
          )

          generate_tokens_response(user, client, cached_data[:scopes], refresh_token)
        end

        def generate_tokens_response(user, client, scopes, refresh_token)
          now = Time.current.to_i

          # Payload for ID Token (OIDC)
          id_token_payload = {
            iss: issuer,
            sub: user.id.to_s,
            aud: client.client_id,
            exp: 1.hour.from_now.to_i,
            iat: now,
            auth_time: now,
            email: user.email,
            name: user.full_name,
            given_name: user.first_name,
            family_name: user.last_name
          }

          # Payload for Access Token
          access_token_payload = {
            iss: issuer,
            sub: user.id.to_s,
            tenant_id: user.tenant_id.to_s,
            aud: client.client_id,
            exp: 1.hour.from_now.to_i,
            iat: now,
            scopes: scopes
          }

          id_token = JWT.encode(id_token_payload, jwks_manager.rsa_key, "RS256", { kid: jwks_manager.jwk[:kid] })
          access_token = JWT.encode(access_token_payload, jwks_manager.rsa_key, "RS256", { kid: jwks_manager.jwk[:kid] })

          success({
            access_token: access_token,
            token_type: "Bearer",
            expires_in: 3600,
            id_token: id_token,
            refresh_token: refresh_token,
            scope: scopes
          }, meta: { status: :ok })
        end

        def jwks_manager
          ::Services::Identity::JwksManager
        end
      end
    end
  end
end
