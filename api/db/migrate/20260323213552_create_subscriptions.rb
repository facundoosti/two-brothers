class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :tenant, null: false, foreign_key: true
      t.date   :started_at, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end

    add_index :subscriptions, %i[tenant_id status]
  end
end
