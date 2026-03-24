class BillingPeriod < ApplicationRecord
  belongs_to :subscription

  enum :status, { pending: "pending", paid: "paid", overdue: "overdue" }
  enum :plan,   { penetracion: "penetracion", puente: "puente", adopcion: "adopcion" }

  validates :year, :month, :billing_month_number, :plan, :usd_base, :blue_rate,
            :base_ars, :variable_pct, :delivered_sales_ars, :variable_ars,
            :total_ars, :status, presence: true

  def self.generate_for(subscription, year, month)
    rate = ExchangeRate.for(Date.new(year, month, 1))
    raise I18n.t("errors.billing.no_exchange_rate", year: year, month: month) unless rate

    billing_month = subscription.billing_month_for(year, month)
    plan          = subscription.plan_for_month(billing_month)

    usd_base = plan == :adopcion ? 25.0 : 20.0
    base_ars = usd_base * rate.blue_rate

    variable_pct = case plan
                   when :penetracion then 0.0
                   when :puente      then 0.003
                   when :adopcion    then 0.005
                   end

    delivered_sales = fetch_delivered_sales(subscription.tenant, year, month)
    variable_ars    = delivered_sales * variable_pct
    total_ars       = base_ars + variable_ars

    create!(
      subscription:         subscription,
      year:                 year,
      month:                month,
      billing_month_number: billing_month,
      plan:                 plan,
      usd_base:             usd_base,
      blue_rate:            rate.blue_rate,
      base_ars:             base_ars,
      variable_pct:         variable_pct,
      delivered_sales_ars:  delivered_sales,
      variable_ars:         variable_ars,
      total_ars:            total_ars,
      status:               :pending,
      due_date:             Date.new(year, month, 1).next_month + 4
    )
  end

  def self.fetch_delivered_sales(tenant, year, month)
    Apartment::Tenant.switch(tenant.subdomain) do
      Order
        .where(status: "delivered")
        .where(
          updated_at: Date.new(year, month, 1).beginning_of_day..
                      Date.new(year, month, -1).end_of_day
        )
        .sum(:total)
    end
  end
end
