class CreateExchangeRates < ActiveRecord::Migration[8.0]
  def change
    create_table :exchange_rates do |t|
      t.integer :year,  null: false
      t.integer :month, null: false
      t.decimal :blue_rate, null: false, precision: 10, scale: 2
      t.timestamps
    end

    add_index :exchange_rates, %i[year month], unique: true
  end
end
