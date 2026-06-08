module Identity
  class PasswordsController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    result = UseCases::Identity::ChangePassword.new.call(
      user: @user,
      password: params[:password],
      password_challenge: params[:password_challenge],
      tenant: System::Current.tenant,
      revoke_others: params[:revoke_others] == "1"
    )

    if result.success?
      redirect_to authenticated_dashboard_path, notice: "Your password has been changed"
    else
      @user.errors.add(:password_challenge, :invalid) if result.error == "Kata sandi saat ini salah."
      flash.now[:alert] = result.error
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_user
      @user = System::Current.user
    end

    def user_params
      params.permit(:password, :password_confirmation, :password_challenge).with_defaults(password_challenge: "")
    end

    def password_challenge_valid?
      @user.authenticate(params[:password_challenge])
    end
end

end