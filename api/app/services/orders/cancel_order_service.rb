module Orders
  class CancelOrderService < ApplicationService
    def initialize(order:, cancelled_by:, reason: nil)
      @order        = order
      @cancelled_by = cancelled_by
      @reason       = reason
    end

    def call
      return failure(I18n.t("errors.order_cannot_be_cancelled")) unless @order.may_cancel?

      ActiveRecord::Base.transaction do
        was_confirmed = @order.confirmed?

        @order.assign_attributes(
          cancelled_by:        @cancelled_by,
          cancelled_at:        Time.current,
          cancellation_reason: @reason
        )
        @order.cancel!

        if was_confirmed
          quantity = @order.order_items.sum(:quantity)
          stock    = DailyStock.today
          stock.update!(used: [ stock.used - quantity, 0 ].max)
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
