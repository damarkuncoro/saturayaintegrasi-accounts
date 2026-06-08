module System
  class HealthController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_current_tenant!, raise: false
  skip_before_action :authenticate_api_user!, raise: false
  skip_after_action :verify_authorized, raise: false
  skip_after_action :verify_policy_scoped, raise: false

  def show
    render json: { status: "OK", timestamp: Time.current }
  end

  def ready
    # Check database connection
    db_ok = ActiveRecord::Base.connection.active? rescue false

    # Check redis connection
    redis_ok = begin
      url = ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
      Redis.new(url: url).ping == "PONG"
    rescue
      false
    end

    if db_ok && redis_ok
      render json: { status: "READY", services: { db: "UP", redis: "UP" } }
    else
      render json: {
        status: "UNREADY",
        services: {
          db: db_ok ? "UP" : "DOWN",
          redis: redis_ok ? "UP" : "DOWN"
        }
      }, status: :service_unavailable
    end
  end
end

end