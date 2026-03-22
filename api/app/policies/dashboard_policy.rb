class DashboardPolicy < ApplicationPolicy
  def show? = admin?
end
