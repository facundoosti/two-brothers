class OrderStatusChannel < ApplicationCable::Channel
  # Clients subscribe in two modes:
  #   { channel: "OrderStatusChannel", order_id: 42 }  → customer or admin on order detail
  #   { channel: "OrderStatusChannel" }                 → admin on list/dashboard (all orders)
  def subscribed
    if params[:order_id]
      order = Order.find(params[:order_id])
      stream_from "order_status_#{order.id}"
    elsif current_user.admin?
      stream_from "admin_orders"
    else
      reject
    end
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def unsubscribed
    stop_all_streams
  end
end
