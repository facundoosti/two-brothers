module Delivery
  class UpdateAssignmentStatusService < ApplicationService
    def initialize(assignment:, new_status:)
      @assignment = assignment
      @new_status = new_status
    end

    def call
      case @new_status
      when "in_transit"
        return failure(I18n.t("errors.transition_not_allowed")) unless @assignment.may_depart?
        ActiveRecord::Base.transaction do
          @assignment.depart!
          @assignment.update_columns(departed_at: Time.current)
          order = @assignment.order
          order.start_delivering! if order.may_start_delivering?
        end
      when "delivered"
        return failure(I18n.t("errors.transition_not_allowed")) unless @assignment.may_deliver?
        ActiveRecord::Base.transaction do
          @assignment.deliver!
          @assignment.update_columns(delivered_at: Time.current)
          @assignment.order.mark_delivered!
        end
      else
        return failure(I18n.t("errors.invalid_status_value"))
      end

      success(@assignment)
    rescue AASM::InvalidTransition => e
      failure(e.message)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.message)
    end
  end
end
