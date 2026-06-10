class Identity::EmailVerificationsController < ApplicationController
  skip_before_action :require_authentication, only: :show

  def show
    result = UseCases::Identity::VerifyEmail.new.execute(
      token_digest: params[:sid],
      tenant: System::Current.tenant
    )

    if result.success?
      redirect_to authenticated_dashboard_path, notice: "Thank you for verifying your email address"
    else
      redirect_to sign_in_path, alert: result.error
    end
  end

  def create
    result = UseCases::Identity::ResendEmailVerification.new.execute(
      user: System::Current.user,
      tenant: System::Current.tenant
    )

    if result.success?
      redirect_to authenticated_dashboard_path, notice: "We sent a verification email to your email address"
    else
      redirect_to authenticated_dashboard_path, alert: result.error
    end
  end
end
