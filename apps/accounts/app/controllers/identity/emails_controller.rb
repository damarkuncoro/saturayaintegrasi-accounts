class Identity::EmailsController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    result = UseCases::Identity::UpdateEmail.new.execute(
      user: @user,
      new_email: params[:email],
      password_challenge: params[:password_challenge],
      tenant: System::Current.tenant
    )

    if result.success?
      redirect_to authenticated_dashboard_path, notice: "Your email has been changed. Please check your inbox for verification."
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
      params.permit(:email, :password_challenge).with_defaults(password_challenge: "")
    end

    def password_challenge_valid?
      @user.authenticate(params[:password_challenge])
    end
end
