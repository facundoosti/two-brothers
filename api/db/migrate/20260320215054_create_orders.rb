class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :modality, null: false, default: 0
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.integer :payment_method, null: false, default: 0
      t.string :delivery_address
      t.bigint :created_by_id
      t.bigint :cancelled_by_id
      t.datetime :cancelled_at
      t.string :cancellation_reason

      t.timestamps
    end

    add_foreign_key :orders, :users, column: :created_by_id
    add_foreign_key :orders, :users, column: :cancelled_by_id
    add_index :orders, :created_by_id
    add_index :orders, :cancelled_by_id
  end
end
