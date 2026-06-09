# frozen_string_literal: true

module SatuRayaCommons
  class Config
    class << self
      attr_writer :app_domain, :accounts_host, :brand_name, :brand_logo_url, 
                  :brand_primary_color, :brand_privacy_url, :brand_terms_url, :brand_slug,
                  :support_email, :smtp_from, :jwt_issuer

      def app_domain
        val = @app_domain.respond_to?(:call) ? @app_domain.call : @app_domain
        val || ENV.fetch("APP_DOMAIN", "satu-raya.dev")
      end

      def accounts_host
        val = @accounts_host.respond_to?(:call) ? @accounts_host.call : @accounts_host
        val || ENV.fetch("APP_HOST", "accounts.#{app_domain}")
      end

      def brand_name
        val = @brand_name.respond_to?(:call) ? @brand_name.call : @brand_name
        val || ENV.fetch("BRAND_NAME", "Satu Raya")
      end

      def brand_logo_url
        val = @brand_logo_url.respond_to?(:call) ? @brand_logo_url.call : @brand_logo_url
        val || ENV.fetch("BRAND_LOGO_URL", nil)
      end

      def brand_primary_color
        val = @brand_primary_color.respond_to?(:call) ? @brand_primary_color.call : @brand_primary_color
        val || ENV.fetch("BRAND_PRIMARY_COLOR", "#4f46e5")
      end

      def brand_privacy_url
        val = @brand_privacy_url.respond_to?(:call) ? @brand_privacy_url.call : @brand_privacy_url
        val || ENV.fetch("BRAND_PRIVACY_URL", "https://#{app_domain}/privacy")
      end

      def brand_terms_url
        val = @brand_terms_url.respond_to?(:call) ? @brand_terms_url.call : @brand_terms_url
        val || ENV.fetch("BRAND_TERMS_URL", "https://#{app_domain}/terms")
      end

      def brand_slug
        val = @brand_slug.respond_to?(:call) ? @brand_slug.call : @brand_slug
        val || ENV.fetch("BRAND_SLUG", "satu-raya")
      end

      def support_email
        val = @support_email.respond_to?(:call) ? @support_email.call : @support_email
        val || ENV.fetch("BRAND_SUPPORT_EMAIL", "support@satu-raya.id")
      end

      def smtp_from
        val = @smtp_from.respond_to?(:call) ? @smtp_from.call : @smtp_from
        val || ENV.fetch("SMTP_FROM", support_email)
      end

      def jwt_issuer
        val = @jwt_issuer.respond_to?(:call) ? @jwt_issuer.call : @jwt_issuer
        val || ENV.fetch("JWT_ISSUER", "https://#{accounts_host}")
      end

      def validate!
        errors = []
        errors << "BRAND_NAME is missing" if brand_name.blank?
        errors << "APP_DOMAIN is missing" if app_domain.blank?
        errors << "APP_HOST is missing" if accounts_host.blank?
        
        {
          brand_logo_url: brand_logo_url,
          brand_privacy_url: brand_privacy_url,
          brand_terms_url: brand_terms_url,
          jwt_issuer: jwt_issuer
        }.each do |key, url|
          next if url.blank?
          unless url =~ URI::DEFAULT_PARSER.make_regexp(%w[http https])
            errors << "#{key} must be a valid HTTP/HTTPS URL (got: #{url})"
          end
        end

        if errors.any?
          raise "Configuration Error in SatuRayaCommons::Config:\n- #{errors.join("\n- ")}"
        end
      end
    end
  end
end
