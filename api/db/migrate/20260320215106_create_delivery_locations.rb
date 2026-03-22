class CreateDeliveryLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_locations do |t|
      t.references :delivery_assignment, null: false, foreign_key: true
      t.decimal :latitude
      t.decimal :longitude
      t.datetime :recorded_at

      t.timestamps
    end
  end
end
