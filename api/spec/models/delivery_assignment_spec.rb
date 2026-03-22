require "rails_helper"

RSpec.describe DeliveryAssignment, type: :model do
  describe "associations" do
    it { should belong_to(:order) }
    it { should belong_to(:user) }
    it { should have_many(:delivery_locations).dependent(:destroy) }
  end

  describe "AASM state machine" do
    subject(:assignment) { create(:delivery_assignment) }

    it "starts in assigned state" do
      expect(assignment).to be_assigned
    end

    describe "#depart" do
      it "transitions from assigned to in_transit" do
        assignment.depart!
        expect(assignment).to be_in_transit
      end
    end

    describe "#deliver" do
      before { assignment.depart! }

      it "transitions from in_transit to delivered" do
        assignment.deliver!
        expect(assignment).to be_delivered
      end
    end

    it "cannot deliver directly from assigned" do
      expect { assignment.deliver! }.to raise_error(AASM::InvalidTransition)
    end
  end
end
