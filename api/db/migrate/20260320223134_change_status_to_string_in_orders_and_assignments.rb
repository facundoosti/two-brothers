class ChangeStatusToStringInOrdersAndAssignments < ActiveRecord::Migration[8.0]
  ORDER_STATUS_MAP = {
    0 => "pending_payment",
    1 => "confirmed",
    2 => "preparing",
    3 => "ready",
    4 => "delivering",
    5 => "delivered",
    6 => "cancelled"
  }.freeze

  ASSIGNMENT_STATUS_MAP = {
    0 => "assigned",
    1 => "in_transit",
    2 => "delivered"
  }.freeze

  def up
    # Orders
    add_column :orders, :status_str, :string, null: false, default: "pending_payment"
    Order.reset_column_information
    execute("UPDATE orders SET status_str = CASE status #{ORDER_STATUS_MAP.map { |k, v| "WHEN #{k} THEN '#{v}'" }.join(' ')} END")
    remove_column :orders, :status
    rename_column :orders, :status_str, :status

    # DeliveryAssignments
    add_column :delivery_assignments, :status_str, :string, null: false, default: "assigned"
    DeliveryAssignment.reset_column_information
    execute("UPDATE delivery_assignments SET status_str = CASE status #{ASSIGNMENT_STATUS_MAP.map { |k, v| "WHEN #{k} THEN '#{v}'" }.join(' ')} END")
    remove_column :delivery_assignments, :status
    rename_column :delivery_assignments, :status_str, :status
  end

  def down
    # Orders
    add_column :orders, :status_int, :integer, null: false, default: 0
    execute("UPDATE orders SET status_int = CASE status #{ORDER_STATUS_MAP.map { |k, v| "WHEN '#{v}' THEN #{k}" }.join(' ')} END")
    remove_column :orders, :status
    rename_column :orders, :status_int, :status

    # DeliveryAssignments
    add_column :delivery_assignments, :status_int, :integer, null: false, default: 0
    execute("UPDATE delivery_assignments SET status_int = CASE status #{ASSIGNMENT_STATUS_MAP.map { |k, v| "WHEN '#{v}' THEN #{k}" }.join(' ')} END")
    remove_column :delivery_assignments, :status
    rename_column :delivery_assignments, :status_int, :status
  end
end
