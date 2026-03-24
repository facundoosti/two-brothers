module Api
  module V1
    class DailyStocksController < BaseController
      # GET /api/v1/daily_stocks
      # Returns today's stock for every active menu item (auto-creates if needed).
      def index
        authorize :daily_stock, :index?
        stocks = MenuItem.where(available: true).where("daily_stock > 0").map do |item|
          DailyStock.for_item_today(item)
        end
        render json: DailyStockBlueprint.render_as_hash(stocks)
      end

      # PATCH /api/v1/daily_stocks/:id
      # Allows admin to override today's total for a specific item's stock record.
      def update
        authorize :daily_stock, :update?
        stock = DailyStock.find(params[:id])
        if stock.update(total: params[:total])
          render json: DailyStockBlueprint.render_as_hash(stock)
        else
          render_error(stock.errors.full_messages.join(", "))
        end
      end
    end
  end
end
