module Identity
  class TwoFactorChallengesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user

  def new
  end

  def create
    result = UseCases::Identity::Mfa::VerifyChallenge.call(
      user: @user,
      code: params[:otp_code],
      tenant: System::Current.tenant,
      ip_address: request.ip,
      user_agent: request.user_agent,
      remember_device: params[:remember_device] == "1"
    )

    if result.success?
      session.delete(:otp_user_id)
      @session = result.meta[:session]

      # Set cookie untuk Trusted Device jika ada
      if result.meta[:trusted_device_fingerprint].present?
        cookies.signed.permanent[trusted_device_cookie_name] = {
          value: result.meta[:trusted_device_fingerprint],
          httponly: true,
          same_site: :lax,
          domain: session_cookie_domain
        }
      end

      cookies.signed.permanent[auth_session_cookie_name] = session_cookie_options(@session.id)
      redirect_to after_authentication_url, notice: "Signed in successfully with 2FA"
    else
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = Identity::User.find_by(id: session[:otp_user_id])
    redirect_to sign_in_path, alert: "Sesi verifikasi berakhir. Silakan login kembali." unless @user
  end
end

end
