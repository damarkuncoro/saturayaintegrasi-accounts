# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.connect_src :self, :https
    policy.font_src    :self, :https, :data
    policy.form_action :self
    policy.frame_ancestors :none
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https
    policy.upgrade_insecure_requests if Rails.env.production?
  end

  # Keep CSP nonces available for the next hardening pass, where inline styles
  # and scripts can be migrated away from report-only policy violations.
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
  config.content_security_policy_nonce_auto = true

  # Start in report-only mode by default while CSP reports are monitored.
  # Set CSP_ENFORCE=true when the remaining asset pipeline checks are clean.
  config.content_security_policy_report_only = !ActiveModel::Type::Boolean.new.cast(ENV.fetch("CSP_ENFORCE", false))
end
