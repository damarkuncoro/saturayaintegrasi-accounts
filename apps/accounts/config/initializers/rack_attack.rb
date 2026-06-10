# frozen_string_literal: true

# Rate limiting for API endpoints
# Disable in test environment by default, but allow enabling dynamically
Rack::Attack.enabled = !Rails.env.test?

class Rack::Attack
  # Throttle login attempts by IP (60 requests per minute)
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
