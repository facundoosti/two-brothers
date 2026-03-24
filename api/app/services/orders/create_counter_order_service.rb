module Orders
  class CreateCounterOrderService < ApplicationService
    MAX_QUANTITY_PER_ITEM = 10

    def initialize(admin:, params:)
      @admin  = admin
      @params = params
    end

    def call
      Array(@params[:order_items_attributes]).each do |item_attr|
        menu_item = MenuItem.find_by(id: item_attr[:menu_item_id])
        quantity  = item_attr[:quantity].to_i

        return failure(I18n.t("errors.item_no_stock", name: menu_item&.name || "desconocido")) unless menu_item&.stock_available?
        return failure(I18n.t("errors.max_quantity_per_item", max: MAX_QUANTITY_PER_ITEM)) if quantity > MAX_QUANTITY_PER_ITEM

        stock = DailyStock.for_item_today(menu_item)
        return failure(I18n.t("errors.insufficient_stock_item", name: menu_item.name, available: stock.available)) unless stock.available?(quantity)
      end

      ActiveRecord::Base.transaction do
        order = @admin.orders.build(@params.merge(modality: :pickup))
        order.created_by = @admin
        order.save!

        order.confirm_payment!

        order.order_items.each do |item|
          stock = DailyStock.for_item_today(item.menu_item)
          stock.update!(used: stock.used + item.quantity)
        end

        return success(order.reload)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    rescue AASM::InvalidTransition => e
      failure(e.message)
    end
  end
end
