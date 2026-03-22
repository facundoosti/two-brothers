class DeliveryLocation < ApplicationRecord
  belongs_to :delivery_assignment

  validates :latitude, presence: true, numericality: true
  validates :longitude, presence: true, numericality: true
  validates :recorded_at, presence: true

  scope :latest, -> { order(recorded_at: :desc).first }
end
