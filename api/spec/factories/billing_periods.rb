FactoryBot.define do
  factory :billing_period do
    association :subscription
    year                 { Date.today.prev_month.year }
    month                { Date.today.prev_month.month }
    billing_month_number { 1 }
    plan                 { "penetracion" }
    usd_base             { 20.0 }
    blue_rate            { 1415.0 }
    base_ars             { 28300.0 }
    variable_pct         { 0.0 }
    delivered_sales_ars  { 0.0 }
    variable_ars         { 0.0 }
    total_ars            { 28300.0 }
    status               { "pending" }
    due_date             { Date.today.beginning_of_month + 4 }

    trait :paid do
      status { "paid" }
    end

    trait :overdue do
      status  { "overdue" }
      due_date { 30.days.ago.to_date }
    end
  end
end
