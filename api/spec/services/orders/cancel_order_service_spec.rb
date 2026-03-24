require "rails_helper"

RSpec.describe Orders::CancelOrderService, type: :service do
  let(:admin) { create(:user, :admin) }

  describe "cancelling a pending_payment order" do
    let(:order) { create(:order, :with_item) }

    subject(:result) do
      described_class.call(order: order, cancelled_by: admin, reason: "Customer request")
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "transitions order to cancelled" do
      result
      expect(order.reload).to be_cancelled
    end

    it "sets cancelled_by and cancelled_at" do
      result
      order.reload
      expect(order.cancelled_by).to eq(admin)
      expect(order.cancelled_at).to be_present
      expect(order.cancellation_reason).to eq("Customer request")
    end

    it "does not restore stock (was not confirmed)" do
      item  = order.order_items.first
      stock = DailyStock.for_item_today(item.menu_item)
      used_before = stock.used

      result

      expect(stock.reload.used).to eq(used_before)
    end
  end

  describe "cancelling a confirmed order" do
    let(:order) { create(:order, :confirmed, :with_item) }

    before do
      item  = order.order_items.first
      stock = DailyStock.for_item_today(item.menu_item)
      stock.update!(used: item.quantity) # simulate stock deducted at confirmation
    end

    subject(:result) do
      described_class.call(order: order, cancelled_by: admin)
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "restores stock for each item" do
      item  = order.order_items.first
      stock = DailyStock.for_item_today(item.menu_item)

      expect { result }.to change { stock.reload.used }.by(-item.quantity)
    end

    it "does not let used go below zero" do
      item  = order.order_items.first
      stock = DailyStock.for_item_today(item.menu_item)
      stock.update!(used: 0)

      expect { result }.not_to raise_error
      expect(stock.reload.used).to eq(0)
    end
  end

  describe "order cannot be cancelled" do
    let(:order) { create(:order, :preparing) }

    subject(:result) { described_class.call(order: order, cancelled_by: admin) }

    it "returns failure" do
      expect(result).to be_failure
      expect(result.error).to eq(I18n.t("errors.order_cannot_be_cancelled"))
    end

    it "does not change order status" do
      result
      expect(order.reload).to be_preparing
    end
  end

  describe "unexpected AASM::InvalidTransition during transaction" do
    let(:order) { create(:order) }

    before do
      allow_any_instance_of(Order).to receive(:cancel!).and_raise(
        AASM::InvalidTransition.new(order, :cancel, :default)
      )
    end

    it "returns failure" do
      result = described_class.call(order: order, cancelled_by: admin)
      expect(result).to be_failure
    end
  end

  describe "unexpected ActiveRecord::RecordInvalid during transaction" do
    let(:order) { create(:order, :confirmed, :with_item) }

    before do
      item  = order.order_items.first
      stock = DailyStock.for_item_today(item.menu_item)
      stock.update!(used: item.quantity)
      allow_any_instance_of(DailyStock).to receive(:update!).and_raise(
        ActiveRecord::RecordInvalid.new(DailyStock.new)
      )
    end

    it "returns failure" do
      result = described_class.call(order: order, cancelled_by: admin)
      expect(result).to be_failure
    end
  end
end
