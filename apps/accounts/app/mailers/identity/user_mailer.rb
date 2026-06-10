module Identity
  class UserMailer < ApplicationMailer
    helper SatuRayaIdentityUI::BrandViewHelper

    def password_reset_instructions(user, token)
      @user = user
      @token = token
      @brand_config = brand_config

      mail to: @user.email, subject: t("mailers.user_mailer.password_reset.subject", brand_name: @brand_config.name)
    end

    def email_verification_instructions(user, token)
      @user = user
      @token = token
      @brand_config = brand_config

      mail to: @user.email, subject: t("mailers.user_mailer.email_verification.subject", brand_name: @brand_config.name)
    end
  end
end
