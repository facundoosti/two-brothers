class CreateMenuItems < ActiveRecord::Migration[8.0]
  def change
    create_table :menu_items do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.boolean :available, null: false, default: true
      t.string :image_url

      t.timestamps
    end
  end
end
