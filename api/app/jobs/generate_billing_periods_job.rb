class GenerateBillingPeriodsJob < ApplicationJob
  queue_as :billing

  def perform
    last_month = Date.today.prev_month
    year  = last_month.year
    month = last_month.month

    unless ExchangeRate.for(Date.new(year, month, 1))
      Rails.logger.error("[Billing] Sin cotización blue para #{year}/#{month} — job abortado.")
      return
    end

    Subscription.active.each do |subscription|
      BillingPeriod.generate_for(subscription, year, month)
    rescue => e
      Rails.logger.error("[Billing] Error generando período para subscription ##{subscription.id}: #{e.message}")
    end
  end
end
