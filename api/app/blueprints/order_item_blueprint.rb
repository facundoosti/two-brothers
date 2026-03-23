class OrderItemBlueprint < Blueprinter::Base
  identifier :id

  fields :menu_item_id, :quantity, :unit_price, :notes

  field :name do |oi|
    oi.menu_item.name
  end

  field :image_url do |oi|
    oi.menu_item.image.url if oi.menu_item.image.attached?
  end
end
