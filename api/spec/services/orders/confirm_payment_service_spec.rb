require "rails_helper"

RSpec.describe Orders::ConfirmPaymentService, type: :service do
  let!(:stock) { create(:daily_stock, date: Date.current, total: 100, used: 0) }
  let(:order)  { create(:order, :with_item) }

  subject(:result) { described_class.call(order: order) }

  describe "successful confirmation" do
    it "returns success" do
      expect(result).to be_success
    end

    it "transitions order to confirmed" do
      result
      expect(order.reload).to be_confirmed
    end

    it "deducts stock" do
      expect { result }.to change { stock.reload.used }.by(1)
    end

    it "returns the confirmed order in payload" do
      expect(result.payload).to eq(order)
    end
  end

  describe "order not in pending_payment state" do
    let(:order) { create(:order, :confirmed) }

    it "returns failure" do
      expect(result).to be_failure
      expect(result.error).to eq(I18n.t("errors.order_not_pending_payment"))
    end

    it "does not change stock" do
      expect { result }.not_to change { stock.reload.used }
    end
  end

  describe "insufficient stock" do
    before { stock.update!(used: 100) }

    it "returns failure" do
      expect(result).to be_failure
      expect(result.error).to eq(I18n.t("errors.insufficient_stock_confirm"))
    end

    it "does not transition the order" do
      result
      expect(order.reload).to be_pending_payment
    end
  end

  describe "unexpected ActiveRecord::RecordInvalid during transaction" do
    before do
      allow_any_instance_of(DailyStock).to receive(:update!).and_raise(
        ActiveRecord::RecordInvalid.new(DailyStock.new)
      )
    end

    it "returns failure" do
      expect(result).to be_failure
    end
  end

  describe "unexpected AASM::InvalidTransition during transaction" do
    before do
      allow_any_instance_of(Order).to receive(:confirm_payment!).and_raise(
        AASM::InvalidTransition.new(order, :confirm_payment, :default)
      )
    end

    it "returns failure" do
      expect(result).to be_failure
    end
  end
end
