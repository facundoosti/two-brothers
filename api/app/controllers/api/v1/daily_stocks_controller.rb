module Api
  module V1
    class DailyStocksController < BaseController
      # GET /api/v1/daily_stock
      def show
        authorize :daily_stock, :show?
        render json: DailyStockBlueprint.render_as_hash(DailyStock.today)
      end

      # PATCH /api/v1/daily_stock
      def update
        authorize :daily_stock, :update?
        stock = DailyStock.today
        if stock.update(total: params[:total])
          render json: DailyStockBlueprint.render_as_hash(stock)
        else
          render_error(stock.errors.full_messages.join(", "))
        end
      end
    end
  end
end
