class DeliveryAssignmentPolicy < ApplicationPolicy
  # admin ve todos; delivery ve los propios
  def index?         = admin? || delivery?
  def create?        = admin?
  # solo el repartidor dueño del reparto puede actualizar su estado
  def update_status? = delivery? && record.user_id == user.id

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all             if user.admin?
      return scope.where(user: user) if user.delivery?

      scope.none
    end
  end
end
