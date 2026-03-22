class CreateDailyStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_stocks do |t|
      t.date :date
      t.integer :total
      t.integer :used

      t.timestamps
    end
    add_index :daily_stocks, :date, unique: true
  end
end
