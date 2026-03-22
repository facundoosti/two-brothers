class OrderPolicy < ApplicationPolicy
  # customer ve sus órdenes; admin ve todas
  def index?           = admin? || customer?
  def show?            = admin? || record.user_id == user.id
  def create?          = customer? || admin?
  def confirm_payment? = admin?
  def update_status?   = admin?
  def cancel?          = admin?
  def create_counter?  = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all              if user.admin?
      return scope.where(user: user) if user.customer?

      scope.none
    end
  end
end
