# frozen_string_literal: true

module Identity
  class AccountsController < ApplicationController
    before_action :set_user

    def show
    end

    def update
      if @user.update(user_params)
        redirect_to identity_account_path, notice: "Profil berhasil diperbarui."
      else
        render :show, status: :unprocessable_content
      end
    end

    def deactivate
      unless @user.authenticate(params[:password_challenge])
        redirect_to identity_account_path, alert: "Kata sandi salah."
        return
      end

      result = Identity::AccountService.new.deactivate(user: @user, reason: "user_requested")

      if result.success?
        terminate_session
        redirect_to root_path, notice: "Akun Anda telah dinonaktifkan."
      else
        redirect_to identity_account_path, alert: result.error
      end
    end

    private

    def set_user
      @user = System::Current.user
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :phone)
    end
  end
end
