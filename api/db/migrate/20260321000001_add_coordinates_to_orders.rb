class AddCoordinatesToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :latitude, :float
    add_column :orders, :longitude, :float
    add_index :orders, [ :latitude, :longitude ]
  end
end
