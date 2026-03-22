class DeliveryAssignmentBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :assigned_at, :departed_at, :delivered_at, :order_id, :user_id

  view :with_order do
    fields :status, :assigned_at, :departed_at, :delivered_at, :order_id, :user_id

    field :user_name do |assignment|
      assignment.user.name
    end

    field :order do |assignment|
      o = assignment.order
      {
        id:               o.id,
        status:           o.status,
        modality:         o.modality,
        delivery_address: o.delivery_address,
        latitude:         o.latitude,
        longitude:        o.longitude,
        total:            o.total,
        payment_method:   o.payment_method,
        user:             { name: o.user.name },
        order_items:      o.order_items.map { |oi|
          {
            id:         oi.id,
            name:       oi.menu_item.name,
            quantity:   oi.quantity,
            unit_price: oi.unit_price,
            notes:      oi.notes
          }
        }
      }
    end
  end
end
