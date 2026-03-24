module Orders
  class CreateOrderService < ApplicationService
    MAX_QUANTITY_PER_ITEM = 10

    def initialize(user:, params:)
      @user   = user
      @params = params
    end

    def call
      return failure(I18n.t("errors.store_closed")) unless store_open?

      Array(@params[:order_items_attributes]).each do |item_attr|
        menu_item = MenuItem.find_by(id: item_attr[:menu_item_id])
        quantity  = item_attr[:quantity].to_i

        return failure(I18n.t("errors.item_no_stock", name: menu_item&.name || "desconocido")) unless menu_item&.stock_available?
        return failure(I18n.t("errors.max_quantity_per_item", max: MAX_QUANTITY_PER_ITEM)) if quantity > MAX_QUANTITY_PER_ITEM

        stock = DailyStock.for_item_today(menu_item)
        return failure(I18n.t("errors.insufficient_stock_item", name: menu_item.name, available: stock.available)) unless stock.available?(quantity)
      end

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

    def store_open?
      StoreSchedule.open?
    end
  end
end
