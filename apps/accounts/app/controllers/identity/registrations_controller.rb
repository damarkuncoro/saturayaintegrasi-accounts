module Identity
  class RegistrationsController < ApplicationController
  skip_before_action :require_authentication
  before_action :redirect_if_authenticated, only: %i[ new create ]

  def new
    @user = Identity::User.new
  end

  def create
    result = UseCases::Identity::Register.new.call(
      params: safe_user_params,
      tenant: require_current_tenant!
    )

    if result.success?
      @user = result.value
      start_new_session_for(@user)
      redirect_to after_authentication_url, notice: "Welcome! You have signed up successfully"
    else
      @user = Identity::User.new(safe_user_params)
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_content
    end
  end

  private
    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation,
                                    :first_name, :last_name, :phone, :role)
    end

    def safe_user_params
      user_params.merge(role: public_role)
    end

    def public_role
      user_params[:role].in?(%w[worker employer]) ? user_params[:role] : "worker"
    end
end

end
