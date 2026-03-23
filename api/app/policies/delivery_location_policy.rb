class DeliveryLocationPolicy < ApplicationPolicy
  # Solo el repartidor puede registrar su ubicación
  def create? = delivery?

  # `record` es el DeliveryAssignment al que pertenece la location.
  # Admin siempre puede; customer solo si la orden es suya.
  def latest? = admin? ||
                (customer? && record.order.user_id == user.id) ||
                (delivery? && record.user_id == user.id)
end
