class ResetDailyStockJob < ApplicationJob
  queue_as :default

  # Scheduled every day at midnight via Solid Queue (config/recurring.yml).
  # DailyStock.today uses find_or_create_by(date: Date.current), so calling it
  # at 00:00 creates a fresh record for the new day with used: 0.
  def perform
    DailyStock.today
  end
end
