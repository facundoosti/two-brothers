FactoryBot.define do
  factory :menu_item do
    association :category
    sequence(:name) { |n| "Item #{n}" }
    price           { 1500.00 }
    available       { true }
    daily_stock     { 50 }

    trait :unavailable do
      available { false }
    end

    trait :no_stock do
      daily_stock { nil }
    end

    trait :zero_stock do
      daily_stock { 0 }
    end
  end
end
