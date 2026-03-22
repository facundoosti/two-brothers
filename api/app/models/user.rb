class User < ApplicationRecord
  enum :role, { customer: 0, delivery: 1, admin: 2 }
  enum :status, { pending: 0, active: 1 }

  has_many :orders, dependent: :destroy
  has_many :created_orders, class_name: "Order", foreign_key: :created_by_id, dependent: :nullify
  has_many :cancelled_orders, class_name: "Order", foreign_key: :cancelled_by_id, dependent: :nullify
  has_many :delivery_assignments, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :uid, presence: true
  validates :provider, presence: true
  validates :role, presence: true
  validates :status, presence: true

  before_create :generate_api_token

  def self.from_google(payload)
    find_or_initialize_by(provider: "google", uid: payload["sub"]).tap do |user|
      user.email = payload["email"]
      user.name = payload["name"]
      user.avatar_url = payload["picture"]
      user.role ||= :customer
      user.status ||= :active
      user.save!
    end
  end

  def regenerate_api_token!
    update!(api_token: SecureRandom.hex(32))
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
