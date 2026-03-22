class DailyStockPolicy < ApplicationPolicy
  def show?   = admin?
  def update? = admin?
end
