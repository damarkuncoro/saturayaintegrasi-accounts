# frozen_string_literal: true

module Identity
  class OauthController < ApplicationController
    skip_before_action :require_authentication, only: [ :authorize, :consent, :token, :userinfo, :revoke ]

    # GET /oauth/authorize
    def authorize
      @client = SsoClientConfiguration.active.find_by!(client_id: params[:client_id])
      
      # Validasi redirect_uri
      unless @client.redirect_uris.include?(params[:redirect_uri])
        return render json: { error: "invalid_redirect_uri" }, status: :bad_request
      end

      # Simpan params ke session untuk digunakan setelah login
      session[:oauth_params] = params.to_unsafe_h

      # Jika belum login, redirect ke login
      unless authenticated?
        return redirect_to sign_in_path(return_to: request.fullpath), allow_other_host: true
      end

      # Cek apakah user sudah memberikan persetujuan sebelumnya
      existing_consent = UserConsent.find_by(
        user: current_user,
        sso_client_configuration: @client,
        revoked_at: nil
      )

      if existing_consent || params[:prompt] == "none"
        return issue_code_and_redirect
      end

      render :authorize
    end

    # POST /oauth/authorize/consent
    def consent
      @client = SsoClientConfiguration.active.find_by!(client_id: params[:client_id])
      
      unless authenticated?
        return redirect_to sign_in_path(return_to: request.fullpath), allow_other_host: true
      end

      if params[:allow] == "true"
        # Simpan persetujuan user
        scopes = (session.dig(:oauth_params, "scope") || "openid profile email").split(" ")
        scopes_hash = scopes.each_with_object({}) { |scope, hash| hash[scope] = true }

        UserConsent.create!(
          user: current_user,
          sso_client_configuration: @client,
          consented_scopes: scopes_hash,
          granted_at: Time.current,
          consent_signature: SecureRandom.hex(32) # Simple signature
        )
        
        issue_code_and_redirect
      else
        redirect_uri = session.dig(:oauth_params, "redirect_uri")
        redirect_to "#{redirect_uri}?error=access_denied", allow_other_host: true
      end
    end

    # POST /oauth/token
    def token
      client = find_client
      
      if client.nil? || !authenticate_client(client)
        return render json: { error: "invalid_client" }, status: :unauthorized
      end

      cached_data = Rails.cache.read("oauth_code_#{params[:code]}")
      
      if cached_data.nil? || cached_data[:client_id] != client.client_id
        return render json: { error: "invalid_grant" }, status: :bad_request
      end

      # Hapus code setelah digunakan
      Rails.cache.delete("oauth_code_#{params[:code]}")

      user = Identity::User.find(cached_data[:user_id])
      
      # Generate JWT token
      # In OIDC, we usually provide an access_token and an id_token
      now = Time.current.to_i
      
      # Payload for ID Token (OIDC)
      id_token_payload = {
        iss: brand_config.oidc_issuer,
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
        iss: brand_config.oidc_issuer,
        sub: user.id.to_s,
        aud: client.client_id,
        exp: 1.hour.from_now.to_i,
        iat: now,
        scopes: cached_data[:scopes]
      }
      
      # Using HS256 for both for simplicity as per current configuration
      # Note: Real OIDC providers usually use RS256 for ID tokens
      id_token = JWT.encode(id_token_payload, Rails.application.secret_key_base, "HS256")
      access_token = JWT.encode(access_token_payload, Rails.application.secret_key_base, "HS256")

      render json: {
        access_token: access_token,
        token_type: "Bearer",
        expires_in: 3600,
        id_token: id_token,
        scope: cached_data[:scopes]
      }
    end

    # GET /oauth/userinfo
    def userinfo
      token = request.headers["Authorization"]&.split(" ")&.last
      begin
        payload, _header = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: "HS256" })
        user = Identity::User.find(payload["sub"])
        
        render json: {
          sub: user.id.to_s,
          email: user.email,
          name: user.full_name,
          preferred_username: user.username,
          given_name: user.first_name,
          family_name: user.last_name,
          email_verified: user.email_verified?
        }
      rescue JWT::DecodeError
        render json: { error: "invalid_token" }, status: :unauthorized
      rescue ActiveRecord::RecordNotFound
        render json: { error: "user_not_found" }, status: :unauthorized
      end
    end

    # POST /oauth/revoke
    def revoke
      # Basic implementation: tokens are stateless JWTs, so we just return OK
      # or implement a blacklist in Redis if needed.
      render json: { status: "revoked" }
    end

    private

    def issue_code_and_redirect
      oauth_params = session[:oauth_params] || params
      code = SecureRandom.hex(16)
      Rails.cache.write("oauth_code_#{code}", {
        user_id: current_user.id,
        client_id: @client.client_id,
        scopes: oauth_params["scope"],
        redirect_uri: oauth_params["redirect_uri"]
      }, expires_in: 5.minutes)

      redirect_to "#{oauth_params["redirect_uri"]}?code=#{code}&state=#{oauth_params["state"]}", allow_other_host: true
    end

    def find_client
      client_id = params[:client_id] || extract_client_id_from_header
      SsoClientConfiguration.active.find_by(client_id: client_id)
    end

    def extract_client_id_from_header
      auth_header = request.headers["Authorization"]
      return nil unless auth_header&.start_with?("Basic ")
      
      encoded = auth_header.sub("Basic ", "")
      decoded = Base64.decode64(encoded)
      decoded.split(":").first
    rescue
      nil
    end

    def authenticate_client(client)
      # client_secret_post
      if params[:client_secret].present?
        return client.authenticate_client_secret(params[:client_secret])
      end

      # client_secret_basic
      auth_header = request.headers["Authorization"]
      if auth_header&.start_with?("Basic ")
        encoded = auth_header.sub("Basic ", "")
        decoded = Base64.decode64(encoded)
        _id, secret = decoded.split(":")
        return client.authenticate_client_secret(secret)
      end

      false
    end
  end
end
