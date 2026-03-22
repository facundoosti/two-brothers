class CategoryBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :position

  view :with_items do
    fields :name, :position
    association :menu_items, blueprint: MenuItemBlueprint
  end
end
