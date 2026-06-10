# frozen_string_literal: true

require "securerandom"
require "base64"
require "digest"
require "jwt"

module UseCases
  module Identity
    module Oauth
      class ExchangeToken
        class Result
          attr_reader :data, :error, :error_description, :status

          def initialize(data: nil, error: nil, error_description: nil, status: :ok)
            @data = data
            @error = error
            @error_description = error_description
            @status = status
          end

          def success?
            @error.nil?
          end
        end

        def initialize(params:, request_ip:, request_user_agent:, auth_header:, issuer:)
          @params = params
          @request_ip = request_ip
          @request_user_agent = request_user_agent
          @auth_header = auth_header
          @issuer = issuer
        end

        def call
          # 1. client_credentials grant type
          if @params[:grant_type] == "client_credentials"
            return exchange_client_credentials
          end

          # 2. refresh_token grant type
          if @params[:grant_type] == "refresh_token"
            return exchange_refresh_token
          end

          # 3. Default / authorization_code grant type
          exchange_authorization_code
        end

        private

        # --- M2M Client Credentials Grant Flow ---
        def exchange_client_credentials
          client = find_service_client
          if client.nil? || !authenticate_service_client(client)
            return Result.new(error: "invalid_client", status: :unauthorized)
          end

          now = Time.current.to_i
          requested_scopes = @params[:scope] ? @params[:scope].split(" ") : client.allowed_scopes
          invalid_scopes = requested_scopes - client.allowed_scopes
          if invalid_scopes.any?
            return Result.new(error: "invalid_scope", status: :bad_request)
          end

          access_token_payload = {
            iss: @issuer,
            sub: client.client_id,
            tenant_id: client.tenant_id.to_s,
            aud: client.client_id,
            exp: 1.hour.from_now.to_i,
            iat: now,
            scopes: requested_scopes.join(" "),
            client_credentials: true
          }

          access_token = JWT.encode(
            access_token_payload,
            Services::Identity::JwksManager.rsa_key,
            "RS256",
            { kid: Services::Identity::JwksManager.jwk[:kid] }
          )

          Result.new(data: {
            access_token: access_token,
            token_type: "Bearer",
            expires_in: 3600,
            scope: requested_scopes.join(" ")
          })
        end

        # --- Refresh Token Rotation (RTR) Grant Flow ---
        def exchange_refresh_token
          client = find_client
          if client.nil? || !authenticate_client(client)
            return Result.new(error: "invalid_client", status: :unauthorized)
          end

          refresh_token_param = @params[:refresh_token]
          if refresh_token_param.blank?
            return Result.new(error: "invalid_grant", status: :bad_request)
          end

          token_digest = ::Identity::JwtRefreshToken.digest(refresh_token_param)
          refresh_token_record = ::Identity::JwtRefreshToken.find_by(token_digest: token_digest)

          if refresh_token_record.nil?
            return Result.new(error: "invalid_grant", status: :bad_request)
          end

          # Replay attack check: if token is already revoked, revoke the whole family
          if refresh_token_record.revoked?
            ::Identity::JwtRefreshToken.where(family_id: refresh_token_record.family_id).update_all(revoked_at: Time.current)
            return Result.new(error: "invalid_grant", status: :bad_request)
          end

          if refresh_token_record.expired?
            return Result.new(error: "invalid_grant", status: :bad_request)
          end

          if refresh_token_record.sso_client_configuration_id != client.id
            return Result.new(error: "invalid_grant", status: :bad_request)
          end

          user = refresh_token_record.user
          if !user.active? || !user.tenant.active?
            return Result.new(error: "invalid_grant", status: :bad_request)
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
              ip_address: @request_ip,
              user_agent: @request_user_agent
            )

            refresh_token_record.update!(
              revoked_at: Time.current,
              replaced_by_id: new_record.id
            )
          end

          # Generate JWT token
          now = Time.current.to_i
          scopes_list = new_record.scopes.join(" ")

          # Payload for ID Token (OIDC)
          id_token_payload = {
            iss: @issuer,
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
            iss: @issuer,
            sub: user.id.to_s,
            tenant_id: user.tenant_id.to_s,
            aud: client.client_id,
            exp: 1.hour.from_now.to_i,
            iat: now,
            scopes: scopes_list
          }

          id_token = JWT.encode(
            id_token_payload,
            Services::Identity::JwksManager.rsa_key,
            "RS256",
            { kid: Services::Identity::JwksManager.jwk[:kid] }
          )
          access_token = JWT.encode(
            access_token_payload,
            Services::Identity::JwksManager.rsa_key,
            "RS256",
            { kid: Services::Identity::JwksManager.jwk[:kid] }
          )

          Result.new(data: {
            access_token: access_token,
            token_type: "Bearer",
            expires_in: 3600,
            id_token: id_token,
            refresh_token: new_refresh_token,
            scope: scopes_list
          })
        end

        # --- Authorization Code Grant Flow (with PKCE) ---
        def exchange_authorization_code
          client = find_client
          if client.nil? || !authenticate_client(client)
            return Result.new(error: "invalid_client", status: :unauthorized)
          end

          cached_data = Rails.cache.read("oauth_code_#{@params[:code]}")
          if cached_data.nil? || cached_data[:client_id] != client.client_id
            return Result.new(error: "invalid_grant", status: :bad_request)
          end

          # PKCE verification if challenge is present
          if cached_data[:code_challenge].present?
            code_verifier = @params[:code_verifier]
            if code_verifier.blank?
              return Result.new(error: "invalid_request", error_description: "code_verifier is required", status: :bad_request)
            end

            challenge_method = cached_data[:code_challenge_method] || "plain"
            if challenge_method == "S256"
              calculated = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).tr("=", "")
            elsif challenge_method == "plain"
              calculated = code_verifier
            else
              return Result.new(error: "invalid_request", error_description: "Unsupported code_challenge_method", status: :bad_request)
            end

            if calculated != cached_data[:code_challenge]
              return Result.new(error: "invalid_grant", error_description: "PKCE verification failed", status: :bad_request)
            end
          end

          # Hapus code setelah digunakan
          Rails.cache.delete("oauth_code_#{@params[:code]}")

          user = ::Identity::User.find(cached_data[:user_id])
          now = Time.current.to_i

          # Payload for ID Token (OIDC)
          id_token_payload = {
            iss: @issuer,
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
            iss: @issuer,
            sub: user.id.to_s,
            tenant_id: user.tenant_id.to_s,
            aud: client.client_id,
            exp: 1.hour.from_now.to_i,
            iat: now,
            scopes: cached_data[:scopes]
          }

          id_token = JWT.encode(
            id_token_payload,
            Services::Identity::JwksManager.rsa_key,
            "RS256",
            { kid: Services::Identity::JwksManager.jwk[:kid] }
          )
          access_token = JWT.encode(
            access_token_payload,
            Services::Identity::JwksManager.rsa_key,
            "RS256",
            { kid: Services::Identity::JwksManager.jwk[:kid] }
          )

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
            ip_address: @request_ip,
            user_agent: @request_user_agent
          )

          Result.new(data: {
            access_token: access_token,
            token_type: "Bearer",
            expires_in: 3600,
            id_token: id_token,
            refresh_token: refresh_token,
            scope: cached_data[:scopes]
          })
        end

        # --- Client Lookup and Authentication Helpers ---
        def find_client
          client_id = @params[:client_id] || extract_client_id_from_header
          ::Identity::SsoClientConfiguration.active.find_by(client_id: client_id)
        end

        def extract_client_id_from_header
          return nil unless @auth_header&.start_with?("Basic ")
          
          encoded = @auth_header.sub("Basic ", "")
          decoded = Base64.decode64(encoded)
          decoded.split(":").first
        rescue
          nil
        end

        def authenticate_client(client)
          if @params[:client_secret].present?
            return client.authenticate_client_secret(@params[:client_secret])
          end

          if @auth_header&.start_with?("Basic ")
            encoded = @auth_header.sub("Basic ", "")
            decoded = Base64.decode64(encoded)
            _id, secret = decoded.split(":")
            return client.authenticate_client_secret(secret)
          end

          false
        end

        def find_service_client
          client_id = @params[:client_id] || extract_service_client_id_from_header
          ::Identity::ServiceClient.active.find_by(client_id: client_id)
        end

        def extract_service_client_id_from_header
          return nil unless @auth_header&.start_with?("Basic ")
          
          encoded = @auth_header.sub("Basic ", "")
          decoded = Base64.decode64(encoded)
          decoded.split(":").first
        rescue
          nil
        end

        def authenticate_service_client(client)
          if @params[:client_secret].present?
            return client.authenticate_secret(@params[:client_secret])
          end

          if @auth_header&.start_with?("Basic ")
            encoded = @auth_header.sub("Basic ", "")
            decoded = Base64.decode64(encoded)
            _id, secret = decoded.split(":")
            return client.authenticate_secret(secret)
          end

          false
        end
      end
    end
  end
end
