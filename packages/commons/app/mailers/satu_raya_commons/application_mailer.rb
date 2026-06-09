module SatuRayaCommons
  class ApplicationMailer < ActionMailer::Base
    default from: -> { SatuRayaCommons::Config.smtp_from }
    layout "mailer"
  end
end
