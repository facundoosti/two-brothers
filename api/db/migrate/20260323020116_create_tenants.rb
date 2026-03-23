class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :name,      null: false
      t.string :subdomain, null: false, index: { unique: true }
      t.boolean :active,   null: false, default: true
      t.timestamps
    end
  end
end
