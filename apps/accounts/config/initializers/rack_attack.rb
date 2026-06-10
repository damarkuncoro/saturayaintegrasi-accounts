# frozen_string_literal: true

# Rate limiting for API endpoints
# Disable in test environment by default, but allow enabling dynamically
Rack::Attack.enabled = !Rails.env.test?

class Rack::Attack
  # Resolve tenant identifier from request headers, JWT, or subdomain/host
  def self.resolve_tenant_identifier(req)
    # 1. Resolve from X-Tenant-ID header (useful for API testing/development)
    tenant_id = req.env["HTTP_X_TENANT_ID"]
    return tenant_id if tenant_id.present?

    # 2. Resolve from JWT Bearer token
    auth_header = req.env["HTTP_AUTHORIZATION"]
    if auth_header&.start_with?("Bearer ")
      token = auth_header.sub("Bearer ", "")
      begin
        decoded = SatuRayaCommons::Security::JwtCodec.decode(token, Rails.application.secret_key_base)
        tid = decoded&.dig(:tenant_id) || decoded&.dig("tenant_id") || decoded&.dig(:tid) || decoded&.dig("tid")
        return tid if tid.present?
      rescue StandardError
        # Fallback to unverified decode
        begin
          payload = JWT.decode(token, nil, false).first
          tid = payload["tenant_id"] || payload["tid"]
          return tid if tid.present?
        rescue StandardError
          nil
        end
      end
    end

    # 3. Resolve from subdomain or domain
    host = req.host.to_s.strip.downcase
    app_domain = SatuRayaCommons::Config.app_domain.to_s.strip.downcase rescue nil
    app_domain ||= "satu-raya.dev"

    if host.end_with?(".#{app_domain}")
      subdomain = host.sub(".#{app_domain}", "")
      # Avoid reserved subdomains
      return subdomain if subdomain.present? && !%w[www api admin accounts app assets static].include?(subdomain)
    end

    host
  end

  # Throttle logins by IP (60 requests per minute)
  throttle("logins/ip", limit: 60, period: 1.minute) do |req|
    if (req.path == "/api/v1/auth/login" || req.path == "/login") && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email (10 attempts per minute per email)
  throttle("logins/email", limit: 10, period: 1.minute) do |req|
    if (req.path == "/api/v1/auth/login" || req.path == "/login") && req.post?
      # Normalize email parameter
      req.params["email"].to_s.downcase.strip
    end
  end

  # Throttle registrations by IP (10 requests per minute per IP)
  throttle("registrations/ip", limit: 10, period: 1.minute) do |req|
    if req.path == "/register" && req.post?
      req.ip
    end
  end

  # Throttle password reset requests by IP (10 requests per minute per IP)
  throttle("password_resets/ip", limit: 10, period: 1.minute) do |req|
    if req.path == "/identity/password_reset" && (req.post? || req.patch? || req.put?)
      req.ip
    end
  end

  # Throttle password reset requests by email (5 attempts per minute per email)
  throttle("password_resets/email", limit: 5, period: 1.minute) do |req|
    if req.path == "/identity/password_reset" && req.post?
      req.params["email"].to_s.downcase.strip
    end
  end

  # General API throttle (1000 requests per minute per IP)
  throttle("api/ip", limit: 1000, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  # Throttle logins by tenant (100 attempts per minute per tenant)
  throttle("logins/tenant", limit: 100, period: 1.minute) do |req|
    if (req.path == "/api/v1/auth/login" || req.path == "/login") && req.post?
      resolve_tenant_identifier(req)
    end
  end

  # Throttle registrations by tenant (20 requests per minute per tenant)
  throttle("registrations/tenant", limit: 20, period: 1.minute) do |req|
    if req.path == "/register" && req.post?
      resolve_tenant_identifier(req)
    end
  end

  # Throttle password reset requests by tenant (20 requests per minute per tenant)
  throttle("password_resets/tenant", limit: 20, period: 1.minute) do |req|
    if req.path == "/identity/password_reset" && (req.post? || req.patch? || req.put?)
      resolve_tenant_identifier(req)
    end
  end

  # Throttle API requests by tenant (500 requests per minute per tenant)
  throttle("api/tenant", limit: 500, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      resolve_tenant_identifier(req)
    end
  end

  # Block suspicious IPs that are making repeated failed login attempts
  blocklist("fail2ban logout endpoints") do |req|
    # Example: block IPs that have made > 100 failed login attempts in the last 5 minutes
    # This can be enhanced with Redis-based tracking if needed
    # For now, a simple check can be added
    false
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    now = Time.now.utc
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ { error: "Rate limit exceeded. Please try again later." }.to_json ]
    ]
  end
end
