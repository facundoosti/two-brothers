require "rails_helper"

RSpec.describe Order, type: :model do
  describe "validations" do
    it { should validate_presence_of(:modality) }
    it { should validate_presence_of(:payment_method) }
    it { should validate_presence_of(:total) }
    it { should validate_numericality_of(:total).is_greater_than_or_equal_to(0) }

    context "delivery modality" do
      subject { build(:order, :delivery) }
      it { should validate_presence_of(:delivery_address) }
    end

    context "pickup modality" do
      subject { build(:order) }
      it { should_not validate_presence_of(:delivery_address) }
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:order_items).dependent(:destroy) }
    it { should have_one(:delivery_assignment).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:modality).with_values(delivery: 0, pickup: 1) }
    it { should define_enum_for(:payment_method).with_values(cash: 0, transfer: 1) }
  end

  describe "AASM state machine" do
    subject(:order) { create(:order) }

    it "starts in pending_payment state" do
      expect(order).to be_pending_payment
    end

    describe "confirm_payment" do
      it "transitions from pending_payment to confirmed" do
        order.confirm_payment!
        expect(order).to be_confirmed
      end
    end

    describe "start_preparing" do
      subject(:order) { create(:order, :confirmed) }

      it "transitions from confirmed to preparing" do
        order.start_preparing!
        expect(order).to be_preparing
      end
    end

    describe "mark_ready" do
      subject(:order) { create(:order, :preparing) }

      it "transitions from preparing to ready" do
        order.mark_ready!
        expect(order).to be_ready
      end
    end

    describe "start_delivering" do
      subject(:order) { create(:order, :ready) }

      it "transitions from ready to delivering" do
        order.start_delivering!
        expect(order).to be_delivering
      end
    end

    describe "mark_delivered" do
      subject(:order) { create(:order, :delivering) }

      it "transitions from delivering to delivered" do
        order.mark_delivered!
        expect(order).to be_delivered
      end
    end

    describe "cancel" do
      it "transitions from pending_payment to cancelled" do
        order.cancel!
        expect(order).to be_cancelled
      end

      it "transitions from confirmed to cancelled" do
        order = create(:order, :confirmed)
        order.cancel!
        expect(order).to be_cancelled
      end

      it "cannot cancel from preparing" do
        order = create(:order, :preparing)
        expect { order.cancel! }.to raise_error(AASM::InvalidTransition)
      end
    end
  end
end
