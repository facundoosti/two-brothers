FactoryBot.define do
  sequence(:email) { |n| "user#{n}@example.com" }
  sequence(:uid)   { |n| "google-uid-#{n}" }

  factory :user do
    provider { "google" }
    uid      { generate(:uid) }
    email    { generate(:email) }
    name     { "Test User" }
    role     { :customer }
    status   { :active }

    trait :admin do
      role { :admin }
    end

    trait :delivery do
      role { :delivery }
    end

    trait :pending do
      status { :pending }
    end
  end
end
