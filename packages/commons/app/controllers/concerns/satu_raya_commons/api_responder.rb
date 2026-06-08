module SatuRayaCommons
  module ApiResponder
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
    end

    def render_success(data: {}, message: "Success", status: :ok, meta: {})
      render json: {
        success: true,
        message: message,
        data: data,
        meta: meta
      }, status: status
    end

    def render_error(message: "Error", status: :bad_request, errors: [])
      render json: {
        success: false,
        message: message,
        errors: errors
      }, status: status
    end

    def render_not_found(exception = nil)
      render_error(
        message: exception&.message || "Resource not found",
        status: :not_found
      )
    end

    def render_forbidden(exception = nil)
      render_error(
        message: exception&.message || "You are not authorized to perform this action",
        status: :forbidden
      )
    end

    def render_unprocessable_entity(exception = nil)
      errors = exception&.record&.errors&.full_messages || []
      render_error(
        message: "Validation failed",
        status: :unprocessable_entity,
        errors: errors
      )
    end

    def render_unauthorized(message = "Invalid or expired token")
      render_error(
        message: message,
        status: :unauthorized
      )
    end
  end
end
