module Api
  module V1
    class ReportsController < BaseController
      # GET /api/v1/reports?period=week|month|year
      def show
        authorize :report, :show?
        period = params[:period].presence_in(%w[week month year]) || "week"
        current_range, prev_range = date_ranges_for(period)

        current_orders = Order.where(created_at: current_range).where.not(status: "cancelled")
        prev_orders    = Order.where(created_at: prev_range).where.not(status: "cancelled")

        render json: {
          stats:              build_stats(current_orders, prev_orders),
          daily_sales:        build_daily_sales(current_orders),
          top_items:          build_top_items(current_orders),
          transition_metrics: build_transition_metrics(current_orders)
        }
      end

      private

      def date_ranges_for(period)
        case period
        when "week"
          current_start = Date.current.beginning_of_week
          prev_start    = current_start - 7.days
        when "month"
          current_start = Date.current.beginning_of_month
          prev_start    = current_start.prev_month
        when "year"
          current_start = Date.current.beginning_of_year
          prev_start    = current_start.prev_year
        end

        prev_end = current_start - 1.day

        [
          current_start.beginning_of_day..Date.current.end_of_day,
          prev_start.beginning_of_day..prev_end.end_of_day
        ]
      end

      def build_stats(current, prev)
        curr_sales = current.sum(:total).to_f
        prev_sales = prev.sum(:total).to_f
        curr_count = current.count
        prev_count = prev.count
        curr_items = OrderItem.where(order: current).sum(:quantity)
        avg_ticket = curr_count > 0 ? curr_sales / curr_count : 0
        prev_avg   = prev_count > 0 ? prev_sales / prev_count : 0

        {
          total_sales:  curr_sales.round(2),
          total_orders: curr_count,
          total_items:  curr_items,
          avg_ticket:   avg_ticket.round(2),
          trends: {
            sales:      pct_trend(curr_sales, prev_sales),
            orders:     pct_trend(curr_count, prev_count),
            avg_ticket: pct_trend(avg_ticket, prev_avg)
          }
        }
      end

      def pct_trend(current, previous)
        return 0.0 if previous.zero?
        ((current - previous) / previous.to_f * 100).round(1)
      end

      def build_daily_sales(orders)
        orders
          .group("DATE(created_at)")
          .order("DATE(created_at) ASC")
          .pluck(Arel.sql("DATE(created_at)::text, SUM(total), COUNT(*)"))
          .map { |day, total, count| { day: day, value: total.to_f, orders: count } }
      end

      def build_top_items(orders)
        OrderItem.where(order: orders)
          .joins(:menu_item)
          .group("menu_items.name")
          .sum(:quantity)
          .sort_by { |_, v| -v }
          .first(5)
          .map { |name, sold| { name: name, sold: sold } }
      end

      # Average minutes for each status transition, based on recorded timestamps.
      # Only completed intervals are included (both endpoints must be non-null).
      def build_transition_metrics(orders)
        delivery_orders = orders.delivery

        {
          # Creación → confirmación de pago (admin reaction time)
          created_to_confirmed:   avg_interval(orders,         "created_at",   "confirmed_at"),
          # Confirmada → en preparación
          confirmed_to_preparing: avg_interval(orders,         "confirmed_at", "preparing_at"),
          # En preparación → lista
          preparing_to_ready:     avg_interval(orders,         "preparing_at", "ready_at"),
          # Lista → en camino (solo delivery)
          ready_to_delivering:    avg_interval(delivery_orders, "ready_at",    "delivering_at"),
          # En camino → entregada (solo delivery)
          delivering_to_delivered: avg_interval(delivery_orders.where.not(delivered_at: nil), "delivering_at", "delivered_at"),
          # Total: creación → entrega
          total:                  avg_interval(orders.where.not(delivered_at: nil), "created_at", "delivered_at")
        }
      end

      # Returns average minutes (Float | nil) between two timestamp columns.
      def avg_interval(scope, from_col, to_col)
        result = scope
          .where("#{from_col} IS NOT NULL AND #{to_col} IS NOT NULL")
          .average(Arel.sql("EXTRACT(EPOCH FROM (#{to_col} - #{from_col})) / 60"))
        result&.to_f&.round(1)
      end
    end
  end
end
