module Orders
  class ConfirmPaymentService < ApplicationService
    def initialize(order:)
      @order = order
    end

    def call
      return failure(I18n.t("errors.order_not_pending_payment")) unless @order.may_confirm_payment?

      stock    = DailyStock.today
      quantity = @order.order_items.sum(:quantity)

      return failure(I18n.t("errors.insufficient_stock_confirm")) unless stock.available?(quantity)

      ActiveRecord::Base.transaction do
        @order.pickup? ? @order.complete_pickup! : @order.confirm_payment!
        @order.update_columns(paid: true)
        stock.update!(used: stock.used + quantity)
      end

      success(@order)
    rescue AASM::InvalidTransition => e
      failure(e.message)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end
  end
end
