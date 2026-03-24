class DailyStock < ApplicationRecord
  belongs_to :menu_item

  validates :date, presence: true, uniqueness: { scope: :menu_item_id }
  validates :total, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :used, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Returns (or lazily creates) today's stock record for a given menu item.
  # total is seeded from menu_item.daily_stock at record creation time.
  def self.for_item_today(menu_item)
    find_or_create_by(menu_item: menu_item, date: Date.current) do |stock|
      stock.total = menu_item.daily_stock.to_i
      stock.used  = 0
    end
  end

  def available
    total - used
  end

  def available?(quantity = 1)
    available >= quantity
  end
end
