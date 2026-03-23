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
      subject(:order) { create(:order, :ready, :delivery) }

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

    describe "complete_pickup" do
      subject(:order) { create(:order) }

      it "transitions from pending_payment to delivered for pickup orders" do
        expect { order.complete_pickup! }.to change { order.status }.to("delivered")
      end

      it "sets both confirmed_at and delivered_at" do
        order.complete_pickup!
        expect(order.confirmed_at).to be_present
        expect(order.delivered_at).to be_present
      end

      it "cannot complete_pickup on delivery modality" do
        delivery_order = create(:order, :delivery, :confirmed)
        expect { delivery_order.complete_pickup! }.to raise_error(AASM::InvalidTransition)
      end
    end

    describe "complete_ready_pickup" do
      subject(:order) { create(:order, :ready) }

      it "transitions from ready to delivered for pickup orders" do
        expect { order.complete_ready_pickup! }.to change { order.status }.to("delivered")
      end

      it "sets delivered_at" do
        order.complete_ready_pickup!
        expect(order.delivered_at).to be_present
      end
    end

    describe "timestamp callbacks" do
      it "sets confirmed_at on confirm_payment!" do
        order.confirm_payment!
        expect(order.confirmed_at).to be_present
      end

      it "sets preparing_at on start_preparing!" do
        order.confirm_payment!
        order.start_preparing!
        expect(order.preparing_at).to be_present
      end

      it "sets ready_at on mark_ready!" do
        order.confirm_payment!
        order.start_preparing!
        order.mark_ready!
        expect(order.ready_at).to be_present
      end

      it "sets delivering_at on start_delivering!" do
        delivery_order = create(:order, :ready, :delivery)
        delivery_order.start_delivering!
        expect(delivery_order.delivering_at).to be_present
      end

      it "sets delivered_at on mark_delivered!" do
        delivering_order = create(:order, :delivering)
        delivering_order.mark_delivered!
        expect(delivering_order.delivered_at).to be_present
      end
    end
  end

  describe "#broadcast_status_change" do
    subject(:order) { create(:order) }

    it "broadcasts to order_status channel when status changes" do
      expect(ActionCable.server).to receive(:broadcast).with("order_status_#{order.id}", hash_including(id: order.id))
      expect(ActionCable.server).to receive(:broadcast).with("admin_orders", hash_including(id: order.id))
      order.confirm_payment!
    end

    it "broadcasts the new status" do
      expect(ActionCable.server).to receive(:broadcast).with("order_status_#{order.id}", hash_including(status: "confirmed"))
      expect(ActionCable.server).to receive(:broadcast).with("admin_orders", anything)
      order.confirm_payment!
    end
  end

  describe "#should_geocode?" do
    it "geocodes delivery orders when address changes" do
      order = build(:order, :delivery)
      expect(order).to receive(:geocode)
      order.valid?
    end

    it "does not geocode pickup orders" do
      order = build(:order)
      expect(order).not_to receive(:geocode)
      order.valid?
    end

    it "does not geocode delivery orders when address has not changed" do
      order = create(:order, :delivery)
      order.reload
      expect(order).not_to receive(:geocode)
      order.valid?
    end
  end
end
