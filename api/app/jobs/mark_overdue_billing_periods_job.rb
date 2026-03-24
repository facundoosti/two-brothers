class MarkOverdueBillingPeriodsJob < ApplicationJob
  queue_as :billing

  def perform
    BillingPeriod
      .where(status: :pending)
      .where("due_date < ?", Date.today)
      .update_all(Arel.sql("status = 'overdue'"))
  end
end
