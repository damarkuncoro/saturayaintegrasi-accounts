# frozen_string_literal: true

# Rate limiting for API endpoints
# Disabled in test environment
return if Rails.env.test?

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
      req.params["email"].to_s.downcase
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
  self.throttled_responder = lambda do |env|
    now = Time.now.utc
    retry_after = (env["rack.attack.match_data"] || {})[:period]

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
