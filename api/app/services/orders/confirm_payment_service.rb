module Orders
  class ConfirmPaymentService < ApplicationService
    def initialize(order:)
      @order = order
    end

    def call
      return failure(I18n.t("errors.order_not_pending_payment")) unless @order.may_confirm_payment?

      # Pre-validate per-item stock before entering the transaction
      @order.order_items.each do |item|
        stock = DailyStock.for_item_today(item.menu_item)
        return failure(I18n.t("errors.insufficient_stock_confirm_item", name: item.menu_item.name)) unless stock.available?(item.quantity)
      end

      ActiveRecord::Base.transaction do
        @order.confirm_payment!
        @order.update_columns(paid: true)

        @order.order_items.each do |item|
          stock = DailyStock.for_item_today(item.menu_item)
          stock.update!(used: stock.used + item.quantity)
        end
      end

      success(@order)
    rescue AASM::InvalidTransition => e
      failure(e.message)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end
  end
end
