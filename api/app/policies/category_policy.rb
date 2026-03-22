class CategoryPolicy < ApplicationPolicy
  # index es público — no se llama authorize (skip_before_action :authenticate_user!)
  def create?  = admin?
  def update?  = admin?
  def destroy? = admin?
end
