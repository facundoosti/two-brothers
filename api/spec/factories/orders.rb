FactoryBot.define do
  factory :order do
    association :user
    modality       { :pickup }
    payment_method { :cash }
    total          { 1500.00 }
    status         { "pending_payment" }

    trait :delivery do
      modality         { :delivery }
      delivery_address { "Av. Corrientes 1234, Dolores" }
      latitude         { -36.3160 }
      longitude        { -57.6800 }
    end

    trait :confirmed do
      status { "confirmed" }
    end

    trait :preparing do
      status { "preparing" }
    end

    trait :ready do
      status { "ready" }
    end

    trait :delivering do
      status { "delivering" }
    end

    trait :delivered do
      status { "delivered" }
    end

    trait :cancelled do
      status         { "cancelled" }
      cancelled_at   { Time.current }
    end

    trait :with_item do
      after(:create) do |order|
        menu_item = create(:menu_item)
        create(:order_item, order: order, menu_item: menu_item)
      end
    end
  end
end
