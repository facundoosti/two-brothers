class Tenant < ApplicationRecord
  has_many :subscriptions, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
                        format: { with: /\A[a-z0-9\-]+\z/, message: :invalid_subdomain }

  scope :active, -> { where(active: true) }
end
