class DailyStock < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :total, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :used, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.today
    find_or_create_by(date: Date.current) do |stock|
      default = Setting["daily_chicken_stock"]&.to_i || 100
      stock.total = default
      stock.used = 0
    end
  end

  def available
    total - used
  end

  def available?(quantity = 1)
    available >= quantity
  end
end
