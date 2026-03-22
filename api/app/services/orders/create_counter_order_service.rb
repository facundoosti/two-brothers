module Orders
  class CreateCounterOrderService < ApplicationService
    def initialize(admin:, params:)
      @admin  = admin
      @params = params
    end

    def call
      quantity = total_chickens(@params[:order_items_attributes])
      return failure(I18n.t("errors.max_chickens_per_order")) if quantity > 4

      stock = DailyStock.today
      return failure(I18n.t("errors.insufficient_stock", available: stock.available)) unless stock.available?(quantity)

      ActiveRecord::Base.transaction do
        order = @admin.orders.build(@params.merge(modality: :pickup))
        order.created_by = @admin
        order.save!

        # Transition directly to confirmed — payment received in person
        order.confirm_payment!
        stock.update!(used: stock.used + quantity)

        return success(order.reload)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    rescue AASM::InvalidTransition => e
      failure(e.message)
    end

    private

    def total_chickens(items)
      Array(items).sum { |i| i[:quantity].to_i }
    end
  end
end
