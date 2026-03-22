FactoryBot.define do
  factory :daily_stock do
    date  { Date.current }
    total { 100 }
    used  { 0 }

    trait :nearly_full do
      used { 98 }
    end

    trait :exhausted do
      used { 100 }
    end
  end
end
