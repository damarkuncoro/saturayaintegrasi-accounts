class Identity::PasswordResetsController < ApplicationController
  skip_before_action :require_authentication

  def create
    result = UseCases::Identity::ResetPasswordRequest.new.call(
      email: params[:email],
      tenant: System::Current.tenant,
      ip_address: request.ip
    )

    if result.success?
      redirect_to sign_in_path, notice: result.meta[:message]
    else
      redirect_to new_identity_password_reset_path, alert: result.error
    end
  end

  def new
  end

  def edit
    @token_digest = params[:sid]
    # Verify token exists and is valid
    token = Identity::PasswordResetToken.for_tenant(System::Current.tenant).unused.not_expired.find_by(token_digest: @token_digest)
    
    unless token
      redirect_to new_identity_password_reset_path, alert: "That password reset link is invalid or has expired"
      return
    end

    @user = token.user
  end

  def update
    token = Identity::PasswordResetToken.for_tenant(System::Current.tenant).unused.not_expired.find_by(token_digest: params[:sid])

    unless token
      redirect_to new_identity_password_reset_path, alert: "Token reset kata sandi tidak valid atau sudah kedaluwarsa."
      return
    end

    @user = token.user

    result = UseCases::Identity::UpdatePassword.new.call(
      token_digest: params[:sid],
      password: params[:password],
      tenant: System::Current.tenant
    )

    if result.success?
      redirect_to sign_in_path, notice: "Your password was reset successfully. Please sign in"
    else
      @token_digest = params[:sid]
      flash.now[:alert] = result.error
      render :edit, status: :unprocessable_content
    end
  end

  private

    def user_params
      params.permit(:password, :password_confirmation)
    end
end
