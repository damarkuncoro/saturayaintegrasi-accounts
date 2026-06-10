class ApplicationController < ActionController::Base
  include SatuRayaCommons::ErrorHandler
  include SatuRayaCommons::ApiResponder
  include SatuRayaCommons::ResultHandler
  include SatuRayaIdentityClient::ControllerUtils

  before_action :require_current_tenant!

  include SatuRayaIdentityClient::Authentication
  include Pundit::Authorization
  # include Pagy::Backend

  helper SatuRayaIdentityUI::BrandViewHelper

  allow_browser versions: :modern

  layout :resolve_layout
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def resolve_layout
    auth_controllers = %w[SessionsController RegistrationsController PasswordResetsController TwoFactorChallengesController EmailVerificationsController OauthController]
    
    if auth_controllers.any? { |name| self.class.name.include?(name) } && !request.xhr?
      "auth"
    else
      "application"
    end
  end

  def require_current_tenant!
    System::Current.tenant || raise(ActionController::BadRequest, "Tenant is not configured for #{request.host}")
  end
end
