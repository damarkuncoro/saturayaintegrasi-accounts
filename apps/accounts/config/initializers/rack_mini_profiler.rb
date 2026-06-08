if defined?(Rack::MiniProfiler)
  Rack::MiniProfiler.config.enabled = Rails.env.development?
end
