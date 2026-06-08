class ApplicationMailer < SatuRayaCommons::ApplicationMailer
  default from: -> { SatuRayaIdentityClient::Identity::BrandConfig.smtp_from }
  layout "satu_raya_ui/mailer"

  private

  def brand_config
    SatuRayaIdentityClient::Identity::BrandConfig
  end
  helper_method :brand_config
end
