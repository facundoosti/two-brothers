class CreateDeliveryAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_assignments do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :assigned_at
      t.datetime :departed_at
      t.datetime :delivered_at

      t.timestamps
    end
  end
end
