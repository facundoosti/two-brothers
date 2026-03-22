class OrderBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :modality, :payment_method, :total, :delivery_fee,
         :delivery_address, :latitude, :longitude, :cancellation_reason, :cancelled_at, :created_at

  field :delivery_assignment_id do |order|
    order.delivery_assignment&.id
  end

  association :user, blueprint: UserBlueprint, view: :minimal
  association :order_items, blueprint: OrderItemBlueprint
end
