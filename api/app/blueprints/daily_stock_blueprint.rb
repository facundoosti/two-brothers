class DailyStockBlueprint < Blueprinter::Base
  identifier :id

  fields :menu_item_id, :date, :total, :used

  field :available do |stock|
    stock.available
  end

  field :menu_item_name do |stock|
    stock.menu_item.name
  end
end
