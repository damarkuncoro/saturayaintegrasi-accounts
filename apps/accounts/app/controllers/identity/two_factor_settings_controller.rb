module Identity
  class TwoFactorSettingsController < ApplicationController
  before_action :set_user

  def show
    @result = UseCases::Identity::Mfa::PrepareTwoFactor.new(user: @user).execute
  end

  def enable
    result = UseCases::Identity::Mfa::EnableTwoFactor.new.execute(
      user: @user,
      otp_code: params[:otp_code],
      password_challenge: params[:password_challenge],
      tenant: System::Current.tenant
    )

    if result.success?
      @backup_codes = result.meta[:backup_codes]
      flash.now[:notice] = "Two-Factor Authentication (2FA) berhasil diaktifkan. Harap simpan kode cadangan Anda."
      render :show
    else
      flash.now[:alert] = result.error
      render :show, status: :unprocessable_content
    end
  end

  def disable
    result = UseCases::Identity::Mfa::DisableTwoFactor.new.execute(
      user: @user,
      otp_code: params[:otp_code],
      password_challenge: params[:password_challenge],
      tenant: System::Current.tenant
    )

    if result.success?
      redirect_to two_factor_settings_path, notice: "Two-Factor Authentication (2FA) berhasil dinonaktifkan."
    else
      flash.now[:alert] = result.error
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = System::Current.user
  end

  def password_challenge_valid?
    @user.authenticate(params[:password_challenge])
  end
end

end
