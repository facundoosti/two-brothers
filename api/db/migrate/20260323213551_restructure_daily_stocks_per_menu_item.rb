class RestructureDailyStocksPerMenuItem < ActiveRecord::Migration[8.0]
  def up
    # Remove existing data — model is being restructured
    execute "TRUNCATE TABLE daily_stocks"

    # Remove the old date-only unique index
    remove_index :daily_stocks, :date

    # Add menu_item reference
    add_reference :daily_stocks, :menu_item, null: false, foreign_key: true

    # New uniqueness: one record per menu_item per day
    add_index :daily_stocks, [ :menu_item_id, :date ], unique: true
  end

  def down
    remove_index :daily_stocks, [ :menu_item_id, :date ]
    remove_reference :daily_stocks, :menu_item, foreign_key: true
    add_index :daily_stocks, :date, unique: true
  end
end
