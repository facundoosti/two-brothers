FactoryBot.define do
  factory :delivery_location do
    association :delivery_assignment
    latitude    { -34.6037 }
    longitude   { -58.3816 }
    recorded_at { Time.current }
  end
end
