class AddStatusTimestampsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :confirmed_at,  :datetime
    add_column :orders, :preparing_at,  :datetime
    add_column :orders, :ready_at,      :datetime
    add_column :orders, :delivering_at, :datetime
    add_column :orders, :delivered_at,  :datetime
  end
end
