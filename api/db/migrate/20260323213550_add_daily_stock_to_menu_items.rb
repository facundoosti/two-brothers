class AddDailyStockToMenuItems < ActiveRecord::Migration[8.0]
  def change
    add_column :menu_items, :daily_stock, :integer
  end
end
