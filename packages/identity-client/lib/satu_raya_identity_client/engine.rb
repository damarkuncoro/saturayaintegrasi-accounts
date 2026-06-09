# frozen_string_literal: true

module SatuRayaIdentityClient
  class Engine < ::Rails::Engine
    isolate_namespace SatuRayaIdentityClient

    initializer "satu_raya_identity_client.configure_commons" do
      if defined?(SatuRayaCommons::Config)
        SatuRayaCommons::Config.app_domain          = -> { SatuRayaIdentityClient::Identity::BrandConfig.app_domain }
        SatuRayaCommons::Config.accounts_host       = -> { SatuRayaIdentityClient::Identity::BrandConfig.accounts_host }
        SatuRayaCommons::Config.brand_name          = -> { SatuRayaIdentityClient::Identity::BrandConfig.name }
        SatuRayaCommons::Config.brand_logo_url      = -> { SatuRayaIdentityClient::Identity::BrandConfig.logo_url }
        SatuRayaCommons::Config.brand_primary_color = -> { SatuRayaIdentityClient::Identity::BrandConfig.primary_color }
        SatuRayaCommons::Config.brand_privacy_url   = -> { SatuRayaIdentityClient::Identity::BrandConfig.privacy_url }
        SatuRayaCommons::Config.brand_terms_url     = -> { SatuRayaIdentityClient::Identity::BrandConfig.terms_url }
        SatuRayaCommons::Config.brand_slug          = -> { SatuRayaIdentityClient::Identity::BrandConfig.slug }
        SatuRayaCommons::Config.support_email       = -> { SatuRayaIdentityClient::Identity::BrandConfig.support_email }
        SatuRayaCommons::Config.smtp_from           = -> { SatuRayaIdentityClient::Identity::BrandConfig.smtp_from }
        SatuRayaCommons::Config.jwt_issuer          = -> { SatuRayaIdentityClient::Identity::BrandConfig.jwt_issuer }
      end
    end
  end
end
