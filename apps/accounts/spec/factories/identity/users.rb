FactoryBot.define do
  factory :user, class: "Identity::User" do
    association :tenant
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { "Password123!456" }
    password_confirmation { "Password123!456" }
    phone { Faker::PhoneNumber.phone_number }
    role { :user }
    verified { false }
    active { true }

    trait :admin do
      role { :admin }
      verified { true }
      first_name { "Admin" }
      last_name { "Identity::User" }
      email { "admin@example.com" }
    end

    trait :support do
      role { :support }
      verified { true }
    end

    trait :unverified do
      verified { false }
    end

    trait :inactive do
      active { false }
    end

    trait :with_verified_email do
      verified { true }
    end
  end

  factory :user_permission, class: "Identity::UserPermission" do
    tenant
    user
    resource_type { "Identity::User" }
    action { "read" }
  end
end
