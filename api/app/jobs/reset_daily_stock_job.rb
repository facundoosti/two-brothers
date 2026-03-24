class ResetDailyStockJob < ApplicationJob
  queue_as :default

  # Scheduled every day at midnight via Solid Queue (config/recurring.yml).
  # Creates a fresh DailyStock record for each active menu item (available: true,
  # daily_stock > 0) for the new day. Records are created with used: 0 and
  # total seeded from MenuItem#daily_stock.
  def perform
    MenuItem.where(available: true).where("daily_stock > 0").find_each do |item|
      DailyStock.for_item_today(item)
    end
  end
end
