require "rails_helper"

RSpec.describe Delivery::UpdateAssignmentStatusService, type: :service do
  let(:order)      { create(:order, :ready, :delivery) }
  let(:assignment) { create(:delivery_assignment, order: order) }

  describe "transitioning to in_transit" do
    subject(:result) { described_class.call(assignment: assignment, new_status: "in_transit") }

    it "returns success" do
      expect(result).to be_success
    end

    it "sets assignment status to in_transit" do
      result
      expect(assignment.reload).to be_in_transit
    end

    it "sets departed_at" do
      result
      expect(assignment.reload.departed_at).to be_present
    end

    it "transitions the order to delivering" do
      result
      expect(order.reload).to be_delivering
    end
  end

  describe "transitioning to delivered" do
    let(:order)      { create(:order, :delivering) }
    let(:assignment) { create(:delivery_assignment, :in_transit, order: order) }

    subject(:result) { described_class.call(assignment: assignment, new_status: "delivered") }

    it "returns success" do
      expect(result).to be_success
    end

    it "sets assignment status to delivered" do
      result
      expect(assignment.reload).to be_delivered
    end

    it "sets delivered_at" do
      result
      expect(assignment.reload.delivered_at).to be_present
    end

    it "transitions the order to delivered" do
      result
      expect(order.reload).to be_delivered
    end
  end

  describe "invalid transition" do
    let(:assignment) { create(:delivery_assignment, :in_transit, order: create(:order, :delivering)) }

    it "cannot go back to in_transit from delivered" do
      delivered_assignment = create(:delivery_assignment, :delivered, order: create(:order, :delivered))
      result = described_class.call(assignment: delivered_assignment, new_status: "in_transit")
      expect(result).to be_failure
    end
  end

  describe "invalid status value" do
    subject(:result) { described_class.call(assignment: assignment, new_status: "unknown") }

    it "returns failure" do
      expect(result).to be_failure
      expect(result.error).to eq(I18n.t("errors.invalid_status_value"))
    end
  end

  describe "unexpected AASM::InvalidTransition during transaction" do
    before do
      allow_any_instance_of(DeliveryAssignment).to receive(:depart!).and_raise(
        AASM::InvalidTransition.new(assignment, :depart, :default)
      )
    end

    it "returns failure" do
      result = described_class.call(assignment: assignment, new_status: "in_transit")
      expect(result).to be_failure
    end
  end

  describe "unexpected ActiveRecord::RecordInvalid during transaction" do
    before do
      allow_any_instance_of(DeliveryAssignment).to receive(:update_columns)
        .and_raise(ActiveRecord::RecordInvalid.new(DeliveryAssignment.new))
    end

    it "returns failure" do
      result = described_class.call(assignment: assignment, new_status: "in_transit")
      expect(result).to be_failure
    end
  end
end
