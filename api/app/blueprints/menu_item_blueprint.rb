class MenuItemBlueprint < Blueprinter::Base
  identifier :id

  fields :category_id, :name, :description, :price, :available, :daily_stock

  field :image_url do |item|
    item.image.url if item.image.attached?
  end
end
