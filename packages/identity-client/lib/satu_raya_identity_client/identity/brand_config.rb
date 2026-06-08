# frozen_string_literal: true

module SatuRayaIdentityClient
  module Identity
    class BrandConfig
      DEFAULT_NAME = "Satu Raya"
      DEFAULT_SLUG = "satu-raya"
      DEFAULT_DOMAIN = "satu-raya.dev"
      DEFAULT_ACCOUNTS_SUBDOMAIN = "accounts"

      class << self
        def name
          env("BRAND_NAME", DEFAULT_NAME)
        end

        def slug
          env("BRAND_SLUG", DEFAULT_SLUG)
        end

        def app_domain
          env("APP_DOMAIN", DEFAULT_DOMAIN)
        end

        def accounts_host
          env("APP_HOST", "#{accounts_subdomain}.#{app_domain}")
        end

        def accounts_subdomain
          env("ACCOUNTS_SUBDOMAIN", DEFAULT_ACCOUNTS_SUBDOMAIN)
        end

        def jobs_host
          env("JOBS_HOST", "jobs.#{app_domain}")
        end

        def jobs_url
          "https://#{jobs_host}"
        end

        def business_host
          env("BUSINESS_HOST", "business.#{app_domain}")
        end

        def business_url
          "https://#{business_host}"
        end

        def standardization_host
          env("STANDARDIZATION_HOST", "standardization.#{app_domain}")
        end

        def primary_color
          env("BRAND_PRIMARY_COLOR", "#4f46e5")
        end

        def logo_url
          ENV["BRAND_LOGO_URL"].presence
        end

        def icon_url
          ENV["BRAND_ICON_URL"].presence || "/icon.png"
        end

        def privacy_url
          ENV["BRAND_PRIVACY_URL"].presence
        end

        def terms_url
          ENV["BRAND_TERMS_URL"].presence
        end

        def auth_layout_variant
          env("AUTH_LAYOUT_VARIANT", "centered")
        end

        def support_email
          env("BRAND_SUPPORT_EMAIL", "support@satu-raya.id")
        end

        def smtp_from
          env("SMTP_FROM", support_email)
        end

        def session_cookie_name
          env("SESSION_COOKIE_NAME", "_satu_raya_session")
        end

        def auth_session_cookie_name
          env("AUTH_SESSION_COOKIE_NAME", "session_id")
        end

        def trusted_device_cookie_name
          env("TRUSTED_DEVICE_COOKIE_NAME", "remember_device")
        end

        def session_cookie_domain
          value = ENV["SESSION_COOKIE_DOMAIN"].presence
          return :all if value.blank? || value == "all"

          value
        end

        def jwt_issuer
          env("JWT_ISSUER", "https://#{accounts_host}")
        end

        def oidc_issuer
          env("OIDC_ISSUER", "https://#{accounts_host}")
        end

        def allowed_redirect_hosts
          configured = ENV["ALLOWED_REDIRECT_HOSTS"].to_s.split(",").map(&:strip).reject(&:blank?)
          return configured if configured.any?

          [
            app_domain,
            accounts_host,
            jobs_host,
            business_host,
            standardization_host
          ].uniq
        end

        private

        def env(key, fallback)
          ENV.fetch(key, fallback).presence || fallback
        end
      end
    end
  end
end
