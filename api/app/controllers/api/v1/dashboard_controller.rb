module Api
  module V1
    class DashboardController < BaseController
      # GET /api/v1/dashboard
      def show
        authorize :dashboard, :show?
        today_orders = Order.where("DATE(created_at) = ?", Date.current)
        stock = DailyStock.today

        render json: {
          orders: {
            total: today_orders.count,
            pending_payment: today_orders.pending_payment.count,
            confirmed: today_orders.confirmed.count,
            preparing: today_orders.preparing.count,
            ready: today_orders.ready.count,
            delivering: today_orders.delivering.count,
            delivered: today_orders.delivered.count,
            cancelled: today_orders.cancelled.count
          },
          stock: {
            total: stock.total,
            used: stock.used,
            available: stock.available
          },
          active_orders: Order.includes(:user)
            .where(status: %w[confirmed preparing ready delivering])
            .order(created_at: :asc)
            .map { active_order_json(_1) }
        }
      end

      private

      def active_order_json(order)
        {
          id: order.id,
          status: order.status,
          modality: order.modality,
          customer_name: order.user.name,
          total: order.total,
          created_at: order.created_at
        }
      end
    end
  end
end
