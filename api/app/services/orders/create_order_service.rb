module Orders
  class CreateOrderService < ApplicationService
    def initialize(user:, params:)
      @user   = user
      @params = params
    end

    def call
      return failure(I18n.t("errors.store_closed")) unless store_open?

      quantity = total_chickens(@params[:order_items_attributes])
      return failure(I18n.t("errors.max_chickens_per_order")) if quantity > 4

      stock = DailyStock.today
      return failure(I18n.t("errors.insufficient_stock", available: stock.available)) unless stock.available?(quantity)

      order = @user.orders.build(@params)
      order.total = order.order_items.sum { |item| item.quantity * item.unit_price }

      if order.delivery? && Setting["delivery_fee_enabled"] == "true"
        order.delivery_fee = Setting["delivery_fee"].to_f
      end

      if order.save
        @user.update_column(:default_address, order.delivery_address) if order.delivery?
        success(order)
      else
        failure(order.errors.full_messages.join(", "))
      end
    end

    private

    def total_chickens(items)
      Array(items).sum { |i| i[:quantity].to_i }
    end

    def store_open?
      StoreSchedule.open?
    end
  end
end
