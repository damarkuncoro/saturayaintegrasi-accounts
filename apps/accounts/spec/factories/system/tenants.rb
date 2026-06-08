FactoryBot.define do
  factory :tenant, class: "System::Tenant" do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:slug) { |n| "company-#{n}" }
    plan { :starter }
    active { true }
    domain { nil }

    trait :active do
      active { true }
    end

    trait :inactive do
      active { false }
    end

    trait :starter do
      plan { :starter }
    end

    trait :pro do
      plan { :pro }
    end

    trait :enterprise do
      plan { :enterprise }
    end
  end
end
