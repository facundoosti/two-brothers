require "rails_helper"

RSpec.describe Orders::CancelOrderService, type: :service do
  let(:admin)  { create(:user, :admin) }
  let!(:stock) { create(:daily_stock, date: Date.current, total: 100, used: 0) }

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
      expect { result }.not_to change { stock.reload.used }
    end
  end

  describe "cancelling a confirmed order" do
    let(:order) { create(:order, :confirmed, :with_item) }

    before { stock.update!(used: 1) }

    subject(:result) do
      described_class.call(order: order, cancelled_by: admin)
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "restores stock" do
      expect { result }.to change { stock.reload.used }.by(-1)
    end

    it "does not let used go below zero" do
      stock.update!(used: 0)
      expect { result }.not_to raise_error
      expect(stock.reload.used).to eq(0)
    end
  end

  describe "order cannot be cancelled" do
    let(:order) { create(:order, :preparing) }

    subject(:result) do
      described_class.call(order: order, cancelled_by: admin)
    end

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
      stock.update!(used: 1)
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
