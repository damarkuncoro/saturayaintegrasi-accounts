# frozen_string_literal: true

module Identity
  class OauthController < ApplicationController
    skip_before_action :require_authentication, only: [ :authorize, :consent, :token, :userinfo, :revoke, :introspect ]
    skip_forgery_protection only: [ :token, :revoke, :introspect ]

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
      if params[:grant_type] == "client_credentials"
        client = find_service_client
        if client.nil? || !authenticate_service_client(client)
          return render json: { error: "invalid_client" }, status: :unauthorized
        end

        now = Time.current.to_i
        requested_scopes = params[:scope] ? params[:scope].split(" ") : client.allowed_scopes
        invalid_scopes = requested_scopes - client.allowed_scopes
        if invalid_scopes.any?
          return render json: { error: "invalid_scope" }, status: :bad_request
        end

        access_token_payload = {
          iss: brand_config.oidc_issuer,
          sub: client.client_id,
          tenant_id: client.tenant_id.to_s,
          aud: client.client_id,
          exp: 1.hour.from_now.to_i,
          iat: now,
          scopes: requested_scopes.join(" "),
          client_credentials: true
        }

        access_token = JWT.encode(access_token_payload, self.class.rsa_key, "RS256", { kid: self.class.jwk[:kid] })

        return render json: {
          access_token: access_token,
          token_type: "Bearer",
          expires_in: 3600,
          scope: requested_scopes.join(" ")
        }
      end

      client = find_client

      if params[:grant_type] == "refresh_token"
        refresh_token_param = params[:refresh_token]
        if refresh_token_param.blank?
          return render json: { error: "invalid_grant" }, status: :bad_request
        end

        token_digest = Identity::JwtRefreshToken.digest(refresh_token_param)
        refresh_token_record = Identity::JwtRefreshToken.find_by(token_digest: token_digest)

        if refresh_token_record.nil?
          return render json: { error: "invalid_grant" }, status: :bad_request
        end

        # Replay attack check: if token is already revoked, revoke the whole family
        if refresh_token_record.revoked?
          Identity::JwtRefreshToken.where(family_id: refresh_token_record.family_id).update_all(revoked_at: Time.current)
          return render json: { error: "invalid_grant" }, status: :bad_request
        end

        if refresh_token_record.expired?
          return render json: { error: "invalid_grant" }, status: :bad_request
        end

        if refresh_token_record.sso_client_configuration_id != client.id
          return render json: { error: "invalid_grant" }, status: :bad_request
        end

        user = refresh_token_record.user
        if !user.active? || !user.tenant.active?
          return render json: { error: "invalid_grant" }, status: :bad_request
        end

        new_refresh_token = "rt_#{SecureRandom.hex(32)}"
        new_digest = Identity::JwtRefreshToken.digest(new_refresh_token)

        new_record = nil
        Identity::JwtRefreshToken.transaction do
          new_record = Identity::JwtRefreshToken.create!(
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

        # Generate JWT token
        now = Time.current.to_i
        scopes_list = new_record.scopes.join(" ")

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
          tenant_id: user.tenant_id.to_s,
          aud: client.client_id,
          exp: 1.hour.from_now.to_i,
          iat: now,
          scopes: scopes_list
        }

        id_token = JWT.encode(id_token_payload, self.class.rsa_key, "RS256", { kid: self.class.jwk[:kid] })
        access_token = JWT.encode(access_token_payload, self.class.rsa_key, "RS256", { kid: self.class.jwk[:kid] })

        return render json: {
          access_token: access_token,
          token_type: "Bearer",
          expires_in: 3600,
          id_token: id_token,
          refresh_token: new_refresh_token,
          scope: scopes_list
        }
      end

      # Default or authorization_code flow
      cached_data = Rails.cache.read("oauth_code_#{params[:code]}")

      if cached_data.nil? || cached_data[:client_id] != client.client_id
        return render json: { error: "invalid_grant" }, status: :bad_request
      end

      # PKCE verification if challenge is present
      if cached_data[:code_challenge].present?
        code_verifier = params[:code_verifier]
        if code_verifier.blank?
          return render json: { error: "invalid_request", error_description: "code_verifier is required" }, status: :bad_request
        end

        challenge_method = cached_data[:code_challenge_method] || "plain"
        if challenge_method == "S256"
          calculated = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).tr("=", "")
        elsif challenge_method == "plain"
          calculated = code_verifier
        else
          return render json: { error: "invalid_request", error_description: "Unsupported code_challenge_method" }, status: :bad_request
        end

        if calculated != cached_data[:code_challenge]
          return render json: { error: "invalid_grant", error_description: "PKCE verification failed" }, status: :bad_request
        end
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
        tenant_id: user.tenant_id.to_s,
        aud: client.client_id,
        exp: 1.hour.from_now.to_i,
        iat: now,
        scopes: cached_data[:scopes]
      }

      # Using HS256 for both for simplicity as per current configuration
      # Note: Real OIDC providers usually use RS256 for ID tokens
      id_token = JWT.encode(id_token_payload, self.class.rsa_key, "RS256", { kid: self.class.jwk[:kid] })
      access_token = JWT.encode(access_token_payload, self.class.rsa_key, "RS256", { kid: self.class.jwk[:kid] })

      # Generate and store refresh token
      refresh_token = "rt_#{SecureRandom.hex(32)}"
      token_digest = Identity::JwtRefreshToken.digest(refresh_token)
      scopes_arr = (cached_data[:scopes] || "openid profile email").split(" ")

      Identity::JwtRefreshToken.create!(
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

      render json: {
        access_token: access_token,
        token_type: "Bearer",
        expires_in: 3600,
        id_token: id_token,
        refresh_token: refresh_token,
        scope: cached_data[:scopes]
      }
    end


    # GET /oauth/userinfo
    def userinfo
      token = request.headers["Authorization"]&.split(" ")&.last
      begin
        payload, _header = decode_jwt(token)
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
      token = params[:token]
      if token.blank?
        return render json: { error: "missing_token" }, status: :bad_request
      end

      # 1. Cek apakah ini refresh token di DB
      token_digest = Identity::JwtRefreshToken.digest(token)
      refresh_token = Identity::JwtRefreshToken.find_by(token_digest: token_digest)
      if refresh_token
        refresh_token.update!(revoked_at: Time.current)
        return render json: { status: "revoked" }
      end

      # 2. Jika bukan refresh token, coba dekode sebagai JWT access token
      begin
        payload, _header = decode_jwt(token)
        exp = payload["exp"]
        ttl = exp - Time.current.to_i
        if ttl > 0
          token_hash = Digest::SHA256.hexdigest(token)
          redis_url = ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
          redis = Redis.new(url: redis_url)
          redis.setex("oauth_blacklisted_token:#{token_hash}", ttl, "1")
        end
      rescue JWT::DecodeError
        # Abaikan error jika token tidak valid/kadaluwarsa sesuai RFC 7009
      end

      render json: { status: "revoked" }
    end

    # POST /oauth/introspect
    def introspect
      client = find_service_client

      if client.nil? || !authenticate_service_client(client)
        return render json: { error: "invalid_client" }, status: :unauthorized
      end

      token = params[:token]
      if token.blank?
        return render json: { error: "missing_token" }, status: :bad_request
      end

      begin
        payload, _header = decode_jwt(token)

        # Cek apakah token bertipe M2M (Service Client)
        service_client = Identity::ServiceClient.active.find_by(client_id: payload["sub"])
        if service_client
          if service_client.tenant.nil? || (service_client.tenant.active? && service_client.tenant_id.to_s == payload["tenant_id"].to_s)
            return render json: {
              active: true,
              client_id: service_client.client_id,
              tenant_id: service_client.tenant_id.to_s,
              scopes: payload["scopes"] || payload["scope"],
              expires_at: Time.at(payload["exp"]).iso8601
            }
          else
            return render json: { active: false }
          end
        end

        user_id = payload["sub"] || payload["user_id"]
        user = Identity::User.find(user_id)

        # Ensure user is active, tenant is active, and matches the token's tenant
        if user.active? && user.tenant.active? && user.tenant_id.to_s == payload["tenant_id"].to_s
          # Fetch user permissions
          # UserPermission overrides
          permissions = user.user_permissions.includes(:permission).map { |up| up.permission.slug }
          # Role permissions
          permissions += user.roles.includes(:permissions).flat_map { |r| r.permissions.map(&:slug) }
          permissions = permissions.uniq

          render json: {
            active: true,
            user_id: user.id.to_s,
            tenant_id: user.tenant_id.to_s,
            role: user.role,
            permissions: permissions,
            expires_at: Time.at(payload["exp"]).iso8601
          }
        else
          render json: { active: false }
        end
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render json: { active: false }
      end
    end

    private

    def issue_code_and_redirect
      oauth_params = session[:oauth_params] || params
      code = SecureRandom.hex(16)
      Rails.cache.write("oauth_code_#{code}", {
        user_id: current_user.id,
        client_id: @client.client_id,
        scopes: oauth_params["scope"],
        redirect_uri: oauth_params["redirect_uri"],
        code_challenge: oauth_params["code_challenge"],
        code_challenge_method: oauth_params["code_challenge_method"]
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

    def find_service_client
      client_id = params[:client_id] || extract_service_client_id_from_header
      Identity::ServiceClient.active.find_by(client_id: client_id)
    end

    def extract_service_client_id_from_header
      auth_header = request.headers["Authorization"]
      return nil unless auth_header&.start_with?("Basic ")

      encoded = auth_header.sub("Basic ", "")
      decoded = Base64.decode64(encoded)
      decoded.split(":").first
    rescue
      nil
    end

    def authenticate_service_client(client)
      if params[:client_secret].present?
        return client.authenticate_secret(params[:client_secret])
      end

      auth_header = request.headers["Authorization"]
      if auth_header&.start_with?("Basic ")
        encoded = auth_header.sub("Basic ", "")
        decoded = Base64.decode64(encoded)
        _id, secret = decoded.split(":")
        return client.authenticate_secret(secret)
      end

      false
    end

    def decode_jwt(token)
      if token.present?
        token_hash = Digest::SHA256.hexdigest(token)
        redis_url = ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
        redis = Redis.new(url: redis_url)
        if redis.get("oauth_blacklisted_token:#{token_hash}").present?
          raise JWT::DecodeError, "Token has been revoked"
        end
      end

      # Cek algoritma token dari header terlebih dahulu
      begin
        header = JWT.decode(token, nil, false)[1]
        algorithm = header["alg"]
      rescue
        algorithm = nil
      end

      if algorithm == "RS256"
        return JWT.decode(token, self.class.rsa_key.public_key, true, { algorithm: "RS256" })
      end

      # Fallback ke HS256 jika alg simetris atau nil
      keys = [ Rails.application.secret_key_base ]
      if ENV["JWT_SECRET_FALLBACKS"].present?
        keys += ENV["JWT_SECRET_FALLBACKS"].split(",").map(&:strip)
      end

      keys.each_with_index do |key, index|
        begin
          return JWT.decode(token, key, true, { algorithm: "HS256" })
        rescue JWT::DecodeError => e
          raise e if index == keys.length - 1
        end
      end
    end

    def self.rsa_key
      @rsa_key ||= begin
        if ENV["JWT_PRIVATE_KEY"].present?
          OpenSSL::PKey::RSA.new(ENV["JWT_PRIVATE_KEY"])
        elsif Rails.application.credentials.jwt_private_key.present?
          OpenSSL::PKey::RSA.new(Rails.application.credentials.jwt_private_key)
        else
          key_file = Rails.root.join("tmp", "jwt_rsa.key")
          if File.exist?(key_file)
            OpenSSL::PKey::RSA.new(File.read(key_file))
          else
            FileUtils.mkdir_p(key_file.dirname)
            key = OpenSSL::PKey::RSA.generate(2048)
            File.write(key_file, key.to_pem)
            key
          end
        end
      end
    end

    def self.base64url_encode(str)
      Base64.urlsafe_encode64(str).tr("=", "")
    end

    def self.jwk
      @jwk ||= begin
        pub = rsa_key.public_key
        {
          kty: "RSA",
          alg: "RS256",
          use: "sig",
          kid: Digest::SHA256.hexdigest(pub.to_der)[0..15],
          n: base64url_encode(pub.n.to_s(2)),
          e: base64url_encode(pub.e.to_s(2))
        }
      end
    end
  end
end
