class Order < ApplicationRecord
  include AASM

  enum :modality, { delivery: 0, pickup: 1 }
  enum :payment_method, { cash: 0, transfer: 1 }

  belongs_to :user
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :order_items, dependent: :destroy
  has_one :delivery_assignment, dependent: :destroy

  accepts_nested_attributes_for :order_items

  geocoded_by :delivery_address
  after_validation :geocode, if: :should_geocode?
  after_commit :broadcast_status_change, on: :update

  validates :modality, presence: true
  validates :payment_method, presence: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :delivery_address, presence: true, if: :delivery?

  aasm column: :status do
    state :pending_payment, initial: true
    state :confirmed
    state :preparing
    state :ready
    state :delivering
    state :delivered
    state :cancelled

    event :confirm_payment do
      transitions from: :pending_payment, to: :confirmed
    end

    event :start_preparing do
      transitions from: :confirmed, to: :preparing
    end

    event :mark_ready do
      transitions from: :preparing, to: :ready
    end

    event :start_delivering do
      transitions from: :ready, to: :delivering
    end

    event :mark_delivered do
      transitions from: :delivering, to: :delivered
    end

    event :cancel do
      transitions from: %i[pending_payment confirmed], to: :cancelled
    end
  end

  private

  def broadcast_status_change
    return unless saved_change_to_status?

    payload = { id: id, status: status }
    ActionCable.server.broadcast("order_status_#{id}", payload)
    ActionCable.server.broadcast("admin_orders", payload)
  end

  def should_geocode?
    delivery? && delivery_address.present? && delivery_address_changed?
  end
end
