module Identity
  class RegistrationsController < ApplicationController
    skip_before_action :require_authentication
    before_action :redirect_if_authenticated, only: %i[ new create ]

    def new
      @user = Identity::User.new
    end

    def create
      result = UseCases::Identity::Register.new.execute(
        params: user_params,
        tenant: require_current_tenant!
      )

      if result.success?
        @user = result.value
        start_new_session_for(@user)
        redirect_to after_authentication_url, notice: "Welcome! You have signed up successfully"
      else
        @user = Identity::User.new(user_params)
        flash.now[:alert] = result.error
        render :new, status: :unprocessable_content
      end
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation,
                                    :first_name, :last_name, :phone)
    end
  end
end
