module Api
  module V1
    class DeliveryAssignmentsController < BaseController
      # GET /api/v1/delivery_assignments
      def index
        authorize DeliveryAssignment
        order_includes = { order: [:user, { order_items: :menu_item }] }
        scope = policy_scope(DeliveryAssignment)
          .includes(:user, **order_includes)
          .order(created_at: :desc)

        @pagy, assignments = pagy(:offset, scope)
        render json: {
          data: DeliveryAssignmentBlueprint.render_as_hash(assignments, view: :with_order),
          pagy: pagy_meta(@pagy)
        }
      end

      # POST /api/v1/delivery_assignments
      def create
        authorize DeliveryAssignment, :create?

        order         = Order.find(params[:order_id])
        delivery_user = User.find(params[:user_id])

        return render_error(I18n.t("errors.not_a_delivery_user")) unless delivery_user.delivery?

        assignment = DeliveryAssignment.create!(
          order:       order,
          user:        delivery_user,
          status:      :assigned,
          assigned_at: Time.current
        )

        assignment = DeliveryAssignment.includes(:user, order: [:user, { order_items: :menu_item }]).find(assignment.id)
        render json: DeliveryAssignmentBlueprint.render_as_hash(assignment, view: :with_order), status: :created
      end

      # PATCH /api/v1/delivery_assignments/:id/status
      def update_status
        assignment = DeliveryAssignment.find(params[:id])
        authorize assignment

        result = Delivery::UpdateAssignmentStatusService.call(
          assignment: assignment,
          new_status: params[:status]
        )

        if result.success?
          render json: DeliveryAssignmentBlueprint.render_as_hash(result.payload, view: :with_order)
        else
          render_error(result.error)
        end
      end
    end
  end
end
