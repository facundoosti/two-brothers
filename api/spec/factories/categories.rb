FactoryBot.define do
  factory :category do
    sequence(:name)     { |n| "Categoría #{n}" }
    sequence(:position) { |n| n }
  end
end
