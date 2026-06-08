module SatuRayaCommons
  module ErrorHandler
    extend ActiveSupport::Concern

    included do
      unless Rails.application.config.consider_all_requests_local
        rescue_from StandardError, with: :render_500
        rescue_from ActionController::RoutingError, with: :render_404
        rescue_from ActiveRecord::RecordNotFound, with: :render_404
      end
    end

    def render_404(exception = nil)
      respond_to do |format|
        format.html { render template: "errors/not_found", status: :not_found, layout: "application" }
        format.json { render json: { success: false, message: "Not Found" }, status: :not_found }
        format.any  { head :not_found }
      end
    end

    def render_500(exception = nil)
      logger.error(exception.message) if exception
      logger.error(exception.backtrace.join("\n")) if exception

      respond_to do |format|
        format.html { render template: "errors/internal_server_error", status: :internal_server_error, layout: "application" }
        format.json { render json: { success: false, message: "Internal Server Error" }, status: :internal_server_error }
        format.any  { head :internal_server_error }
      end
    end
  end
end
