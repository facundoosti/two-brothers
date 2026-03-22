class MenuItemBlueprint < Blueprinter::Base
  identifier :id

  fields :category_id, :name, :description, :price, :available, :image_url
end
