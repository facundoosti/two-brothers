module Api
  module V1
    class OrdersController < BaseController
      # Solo el admin puede avanzar estos estados.
      # "delivered" es responsabilidad del repartidor — se dispara vía
      # DeliveryAssignment#update_status (in_transit → delivered), que internamente
      # llama a order.mark_delivered! dentro de UpdateAssignmentStatusService.
      STATUS_EVENTS = {
        "preparing"  => :start_preparing,
        "ready"      => :mark_ready,
        "delivering" => :start_delivering
      }.freeze

      before_action :set_order, only: %i[show confirm_payment update_status cancel]

      # POST /api/v1/orders/counter
      def create_counter
        authorize Order, :create_counter?
        result = Orders::CreateCounterOrderService.call(admin: current_user, params: counter_order_params)

        if result.success?
          render json: OrderBlueprint.render_as_hash(result.payload), status: :created
        else
          render_error(result.error)
        end
      end

      # GET /api/v1/orders
      def index
        authorize Order
        scope = policy_scope(Order)
          .includes(:user, :order_items, :delivery_assignment)
          .order(created_at: :desc)

        if current_user.admin?
          scope = scope.where(status: params[:status])     if params[:status].present?
          scope = scope.where(modality: params[:modality]) if params[:modality].present?
          scope = scope.where("DATE(created_at) = ?", params[:date]) if params[:date].present?
        end

        @pagy, orders = pagy(:offset, scope)
        render json: { data: OrderBlueprint.render_as_hash(orders), pagy: pagy_meta(@pagy) }
      end

      # GET /api/v1/orders/:id
      def show
        authorize @order
        render json: OrderBlueprint.render_as_hash(@order)
      end

      # POST /api/v1/orders
      def create
        authorize Order, :create?
        result = Orders::CreateOrderService.call(user: current_user, params: order_params)

        if result.success?
          render json: OrderBlueprint.render_as_hash(result.payload), status: :created
        else
          render_error(result.error)
        end
      end

      # PATCH /api/v1/orders/:id/confirm_payment
      def confirm_payment
        authorize @order
        result = Orders::ConfirmPaymentService.call(order: @order)

        if result.success?
          render json: OrderBlueprint.render_as_hash(result.payload)
        else
          render_error(result.error)
        end
      end

      # PATCH /api/v1/orders/:id/status
      def update_status
        authorize @order
        event = STATUS_EVENTS[params[:status]]
        return render_error(I18n.t("errors.invalid_status")) unless event
        return render_error(I18n.t("errors.invalid_transition_from_current")) unless @order.send(:"may_#{event}?")

        @order.send(:"#{event}!")
        render json: OrderBlueprint.render_as_hash(@order)
      rescue AASM::InvalidTransition => e
        render_error(e.message)
      end

      # PATCH /api/v1/orders/:id/cancel
      def cancel
        authorize @order
        result = Orders::CancelOrderService.call(
          order:        @order,
          cancelled_by: current_user,
          reason:       params[:cancellation_reason]
        )

        if result.success?
          render json: OrderBlueprint.render_as_hash(result.payload)
        else
          render_error(result.error)
        end
      end

      private

      def set_order
        @order = Order.find(params[:id])
      end

      def order_params
        params.require(:order).permit(
          :modality, :payment_method, :delivery_address,
          order_items_attributes: [ :menu_item_id, :quantity, :unit_price, :notes ]
        )
      end

      def counter_order_params
        params.require(:order).permit(
          :payment_method,
          order_items_attributes: [ :menu_item_id, :quantity, :unit_price, :notes ]
        )
      end
    end
  end
end
