FactoryBot.define do
  factory :exchange_rate do
    year      { Date.today.year }
    month     { Date.today.month }
    blue_rate { 1415.0 }
  end
end
