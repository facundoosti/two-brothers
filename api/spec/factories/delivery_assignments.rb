FactoryBot.define do
  factory :delivery_assignment do
    association :order
    association :user, factory: [:user, :delivery]
    status      { "assigned" }
    assigned_at { Time.current }

    trait :in_transit do
      status       { "in_transit" }
      departed_at  { Time.current }
    end

    trait :delivered do
      status       { "delivered" }
      departed_at  { 1.hour.ago }
      delivered_at { Time.current }
    end
  end
end
