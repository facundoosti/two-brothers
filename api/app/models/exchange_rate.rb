class ExchangeRate < ApplicationRecord
  validates :year,      presence: true
  validates :month,     presence: true, inclusion: { in: 1..12 }
  validates :blue_rate, presence: true, numericality: { greater_than: 0 }
  validates :year, uniqueness: { scope: :month }

  def self.for(date = Date.today)
    find_by(year: date.year, month: date.month)
  end
end
