FactoryBot.define do
  factory :order_item do
    association :order
    association :menu_item
    quantity   { 1 }
    unit_price { 1500.00 }
  end
end
