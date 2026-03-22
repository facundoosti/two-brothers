module Api
  module V1
    class DeliveryLocationsController < BaseController
      # POST /api/v1/delivery_locations
      def create
        authorize DeliveryLocation, :create?

        assignment = current_user.delivery_assignments.find(params[:delivery_assignment_id])
        location   = assignment.delivery_locations.create!(
          latitude:    params[:latitude],
          longitude:   params[:longitude],
          recorded_at: params[:recorded_at] || Time.current
        )

        render json: DeliveryLocationBlueprint.render_as_hash(location), status: :created
      end

      # GET /api/v1/delivery_assignments/:id/latest_location
      def latest
        assignment = DeliveryAssignment.find(params[:id])
        authorize assignment, :latest?, policy_class: DeliveryLocationPolicy

        location = assignment.delivery_locations.order(recorded_at: :desc).first

        if location
          render json: DeliveryLocationBlueprint.render_as_hash(location)
        else
          render_error(I18n.t("errors.no_location"), status: :not_found)
        end
      end
    end
  end
end
