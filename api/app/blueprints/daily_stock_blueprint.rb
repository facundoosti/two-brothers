class DailyStockBlueprint < Blueprinter::Base
  fields :date, :total, :used

  field :available do |stock|
    stock.available
  end
end
