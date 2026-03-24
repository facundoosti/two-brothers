class DailyStockPolicy < ApplicationPolicy
  def index?  = admin?
  def update? = admin?
end
