FactoryBot.define do
  factory :menu_item do
    association :category
    sequence(:name) { |n| "Item #{n}" }
    price           { 1500.00 }
    available       { true }

    trait :unavailable do
      available { false }
    end
  end
end
