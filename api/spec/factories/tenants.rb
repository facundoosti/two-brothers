FactoryBot.define do
  sequence(:subdomain) { |n| "empresa#{n}" }

  factory :tenant do
    name      { "Empresa Test" }
    subdomain { generate(:subdomain) }
    active    { true }

    trait :inactive do
      active { false }
    end
  end
end
