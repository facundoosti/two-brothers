module SuperadminHelper
  PLAN_LABELS = {
    "penetracion" => "Penetración",
    "puente"      => "Puente",
    "adopcion"    => "Adopción"
  }.freeze

  PLAN_BADGE_CLASSES = {
    "penetracion" => "badge-plan-penetracion",
    "puente"      => "badge-plan-puente",
    "adopcion"    => "badge-plan-adopcion"
  }.freeze

  STATUS_LABELS = {
    "pending" => "Pendiente",
    "paid"    => "Pagado",
    "overdue" => "Vencido"
  }.freeze

  SUBSCRIPTION_STATUS_LABELS = {
    "active"    => "Activo",
    "suspended" => "Suspendida",
    "cancelled" => "Cancelada"
  }.freeze

  def plan_label(plan)
    PLAN_LABELS[plan.to_s] || plan.to_s.capitalize
  end

  def plan_badge_class(plan)
    PLAN_BADGE_CLASSES[plan.to_s] || "badge-inactive"
  end

  def status_label(status)
    STATUS_LABELS[status.to_s] || status.to_s
  end

  def subscription_status_label(status)
    SUBSCRIPTION_STATUS_LABELS[status.to_s] || status.to_s
  end
end
