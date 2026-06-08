module SatuRayaCommons
  class ApplicationMailer < ActionMailer::Base
    default from: -> { SatuRayaIdentityClient::Identity::BrandConfig.smtp_from }
    layout "mailer"
  end
end
