class MenuItem < ApplicationRecord
  has_one_attached :image
  has_many :daily_stocks, dependent: :destroy

  belongs_to :category

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :daily_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # An item is orderable when it is marked available AND has a positive daily quota.
  # daily_stock nil or 0 → blocked.
  def stock_available?
    available? && daily_stock.to_i > 0
  end
end
