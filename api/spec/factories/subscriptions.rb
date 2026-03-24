FactoryBot.define do
  factory :subscription do
    association :tenant
    started_at { Date.today }
    status     { "active" }

    trait :suspended do
      status { "suspended" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
