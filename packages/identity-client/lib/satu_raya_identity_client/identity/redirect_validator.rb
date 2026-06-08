# frozen_string_literal: true

require "uri"

module SatuRayaIdentityClient
  module Identity
    class RedirectValidator
      class << self
        def safe_url(url, fallback:, allowed_hosts: BrandConfig.allowed_redirect_hosts)
          return fallback if url.blank?
          return url if relative_path?(url)

          uri = URI.parse(url)
          return url if allowed_host?(uri.host, allowed_hosts)

          fallback
        rescue URI::InvalidURIError
          fallback
        end

        def allowed_host?(host, allowed_hosts = BrandConfig.allowed_redirect_hosts)
          normalized_host = normalize_host(host)
          return false if normalized_host.blank?

          allowed_hosts.any? do |allowed_host|
            allowed = normalize_host(allowed_host)
            normalized_host == allowed || normalized_host.end_with?(".#{allowed}")
          end
        end

        private

        def relative_path?(url)
          url.start_with?("/") && !url.start_with?("//")
        end

        def normalize_host(host)
          host.to_s.strip.downcase.sub(/\Ahttps?:\/\//, "").split("/").first
        end
      end
    end
  end
end
