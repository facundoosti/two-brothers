require "rails_helper"

RSpec.describe Orders::CreateOrderService, type: :service do
  # Thursday 20:30 Buenos Aires (23:30 UTC) — within business hours
  let(:open_time)  { Time.find_zone("America/Argentina/Buenos_Aires").local(2026, 3, 19, 20, 30, 0) }
  let(:closed_time) { Time.find_zone("America/Argentina/Buenos_Aires").local(2026, 3, 19, 10, 0, 0) }

  let(:customer)  { create(:user) }
  let(:category)  { create(:category) }
  let(:menu_item) { create(:menu_item, category: category, daily_stock: 50) }

  let(:valid_params) do
    {
      modality:       "pickup",
      payment_method: "cash",
      order_items_attributes: [
        { menu_item_id: menu_item.id, quantity: 2, unit_price: 1500.00 }
      ]
    }
  end

  subject(:result) do
    travel_to(open_time) { described_class.call(user: customer, params: valid_params) }
  end

  describe "successful order creation" do
    it "returns success" do
      expect(result).to be_success
    end

    it "creates an order" do
      expect { result }.to change(Order, :count).by(1)
    end

    it "creates associated order items" do
      expect { result }.to change(OrderItem, :count).by(1)
    end

    it "returns the created order in payload" do
      expect(result.payload).to be_a(Order)
    end
  end

  describe "store closed" do
    it "returns failure" do
      result = travel_to(closed_time) { described_class.call(user: customer, params: valid_params) }
      expect(result).to be_failure
      expect(result.error).to eq(I18n.t("errors.store_closed"))
    end

    it "does not create an order" do
      expect {
        travel_to(closed_time) { described_class.call(user: customer, params: valid_params) }
      }.not_to change(Order, :count)
    end
  end

  describe "item without daily stock configured" do
    let(:menu_item) { create(:menu_item, :no_stock, category: category) }

    it "returns failure" do
      result = travel_to(open_time) { described_class.call(user: customer, params: valid_params) }
      expect(result).to be_failure
      expect(result.error).to include(I18n.t("errors.item_no_stock", name: menu_item.name))
    end
  end

  describe "item with daily_stock: 0" do
    let(:menu_item) { create(:menu_item, :zero_stock, category: category) }

    it "returns failure" do
      result = travel_to(open_time) { described_class.call(user: customer, params: valid_params) }
      expect(result).to be_failure
    end
  end

  describe "max quantity per item exceeded" do
    let(:over_limit_params) do
      valid_params.merge(
        order_items_attributes: [
          { menu_item_id: menu_item.id, quantity: 11, unit_price: 1500.00 }
        ]
      )
    end

    it "returns failure" do
      result = travel_to(open_time) { described_class.call(user: customer, params: over_limit_params) }
      expect(result).to be_failure
      expect(result.error).to eq(I18n.t("errors.max_quantity_per_item", max: 10))
    end

    it "does not create an order" do
      expect {
        travel_to(open_time) { described_class.call(user: customer, params: over_limit_params) }
      }.not_to change(Order, :count)
    end
  end

  describe "insufficient stock for item" do
    # Create and exhaust the stock record within travel_to so the date matches
    before do
      travel_to(open_time) do
        stock = DailyStock.for_item_today(menu_item)
        stock.update!(used: 49) # only 1 available, but requesting 2
      end
    end

    it "returns failure" do
      result = travel_to(open_time) { described_class.call(user: customer, params: valid_params) }
      expect(result).to be_failure
      expect(result.error).to include(I18n.t("errors.insufficient_stock_item", name: menu_item.name, available: 1))
    end
  end

  describe "delivery order without address" do
    let(:params_without_address) { valid_params.merge(modality: "delivery") }

    it "returns failure due to validation" do
      result = travel_to(open_time) { described_class.call(user: customer, params: params_without_address) }
      expect(result).to be_failure
    end
  end
end
