class DeliveryAssignment < ApplicationRecord
  include AASM

  belongs_to :order
  belongs_to :user
  has_many :delivery_locations, dependent: :destroy

  aasm column: :status do
    state :assigned, initial: true
    state :in_transit
    state :delivered

    event :depart do
      transitions from: :assigned, to: :in_transit
    end

    event :deliver do
      transitions from: :in_transit, to: :delivered
    end
  end
end
