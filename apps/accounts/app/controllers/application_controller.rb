class ApplicationController < ActionController::Base
  include SatuRayaCommons::ErrorHandler
  include SatuRayaCommons::ApiResponder
  include SatuRayaCommons::ResultHandler
  include SatuRayaIdentityClient::ControllerUtils
  include SatuRayaIdentityClient::Authentication
  include Pundit::Authorization
  # include Pagy::Backend

  helper SatuRayaIdentityUi::BrandViewHelper

  allow_browser versions: :modern

  layout :resolve_layout

  before_action :require_current_tenant!
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def resolve_layout
    if self.class.name.start_with?("Identity::") && !request.xhr?
      "auth"
    else
      "application"
    end
  end

  def require_current_tenant!
    System::Current.tenant || raise(ActionController::BadRequest, "Tenant is not configured for #{request.host}")
  end
end
