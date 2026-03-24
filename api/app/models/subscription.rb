class Subscription < ApplicationRecord
  belongs_to :tenant
  has_many :billing_periods, dependent: :destroy

  enum :status, { active: "active", suspended: "suspended", cancelled: "cancelled" }

  validates :started_at, presence: true
  validates :status, presence: true
  validate :started_at_not_future
  validate :at_most_one_active_or_suspended_per_tenant, on: :create

  def current_billing_month
    billing_month_for(Date.today.year, Date.today.month)
  end

  def billing_month_for(year, month)
    months_elapsed = (year * 12 + month) - (started_at.year * 12 + started_at.month)
    months_elapsed + 1
  end

  def current_plan
    plan_for_month(current_billing_month)
  end

  def plan_for_month(billing_month)
    case billing_month
    when 1..2 then :penetracion
    when 3     then :puente
    else            :adopcion
    end
  end

  private

  def started_at_not_future
    return unless started_at

    errors.add(:started_at, :future_date) if started_at > Date.today
  end

  def at_most_one_active_or_suspended_per_tenant
    return unless tenant_id

    conflict = Subscription
      .where(tenant_id: tenant_id)
      .where(status: %w[active suspended])
      .exists?

    errors.add(:tenant, :already_has_active_subscription) if conflict
  end
end
