FactoryBot.define do
  factory :user_passkey, class: "Identity::UserPasskey" do
    user
    sequence(:external_id) { |n| "external_id_#{n}_#{SecureRandom.hex(8)}" }
    public_key { SecureRandom.hex(64) }
    nickname { "My Browser Device" }
    sign_count { 0 }
  end

  factory :user_consent, class: "Identity::UserConsent" do
    user
    tenant { user.tenant }
    sso_client_configuration { association(:sso_client_configuration, tenant: tenant) }
    consented_scopes { { "nik" => true, "salary" => false, "experience" => true } }
    granted_at { Time.current }
    consent_signature { SecureRandom.hex(32) }

    trait :revoked do
      revoked_at { 1.day.ago }
    end
  end

  factory :trusted_device, class: "Identity::TrustedDevice" do
    user
    tenant { user.tenant }
    sequence(:device_fingerprint) { |n| "fingerprint_#{n}_#{SecureRandom.hex(16)}" }
    user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" }
    ip_address { "127.0.0.1" }
    last_verified_at { Time.current }

    trait :revoked do
      revoked_at { Time.current }
    end
  end

  factory :sso_client_configuration, class: "Identity::SsoClientConfiguration" do
    tenant
    client_name { "Portal Internal Partner" }
    redirect_uris { ["https://partner.#{SatuRayaIdentityClient::Identity::BrandConfig.app_domain}/callback", "https://partner-staging.#{SatuRayaIdentityClient::Identity::BrandConfig.app_domain}/callback"] }
    allowed_scopes { ["openid", "profile", "email"] }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
