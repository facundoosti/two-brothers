class CreateBillingPeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_periods do |t|
      t.references :subscription, null: false, foreign_key: true
      t.integer :year,  null: false
      t.integer :month, null: false
      t.integer :billing_month_number, null: false
      t.string  :plan,  null: false
      t.decimal :usd_base,            null: false, precision: 10, scale: 2
      t.decimal :blue_rate,           null: false, precision: 10, scale: 2
      t.decimal :base_ars,            null: false, precision: 14, scale: 2
      t.decimal :variable_pct,        null: false, precision: 5,  scale: 4
      t.decimal :delivered_sales_ars, null: false, precision: 14, scale: 2
      t.decimal :variable_ars,        null: false, precision: 14, scale: 2
      t.decimal :total_ars,           null: false, precision: 14, scale: 2
      t.string  :status, null: false, default: "pending"
      t.date    :due_date
      t.timestamps
    end

    add_index :billing_periods, %i[subscription_id year month], unique: true
    add_index :billing_periods, :status
    add_index :billing_periods, :due_date
  end
end
