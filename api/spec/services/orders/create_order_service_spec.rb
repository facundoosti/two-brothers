require "rails_helper"

RSpec.describe Orders::CreateOrderService, type: :service do
  # Thursday 20:30 Buenos Aires (23:30 UTC) — within business hours, same UTC date as the stock fixture
  let(:open_time) { Time.find_zone("America/Argentina/Buenos_Aires").local(2026, 3, 19, 20, 30, 0) }

  let(:customer)   { create(:user) }
  let(:category)   { create(:category) }
  let(:menu_item)  { create(:menu_item, category: category) }
  let!(:stock)     { create(:daily_stock, date: Date.new(2026, 3, 19), total: 100, used: 0) }

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
    travel_to(open_time) do
      described_class.call(user: customer, params: valid_params)
    end
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
    let(:closed_time) { Time.find_zone("America/Argentina/Buenos_Aires").local(2026, 3, 19, 10, 0, 0) }

    it "returns failure" do
      result = travel_to(closed_time) do
        described_class.call(user: customer, params: valid_params)
      end
      expect(result).to be_failure
      expect(result.error).to eq(I18n.t("errors.store_closed"))
    end

    it "does not create an order" do
      expect {
        travel_to(closed_time) do
          described_class.call(user: customer, params: valid_params)
        end
      }.not_to change(Order, :count)
    end
  end

  describe "max chickens exceeded" do
    let(:greedy_params) do
      valid_params.merge(
        order_items_attributes: [
          { menu_item_id: menu_item.id, quantity: 5, unit_price: 1500.00 }
        ]
      )
    end

    it "returns failure" do
      result = travel_to(open_time) do
        described_class.call(user: customer, params: greedy_params)
      end
      expect(result).to be_failure
      expect(result.error).to eq(I18n.t("errors.max_chickens_per_order"))
    end
  end

  describe "insufficient stock" do
    before { stock.update!(used: 99) }

    it "returns failure" do
      result = travel_to(open_time) do
        described_class.call(user: customer, params: valid_params)
      end
      expect(result).to be_failure
      expect(result.error).to include(I18n.t("errors.insufficient_stock", available: 1))
    end
  end

  describe "delivery order without address" do
    let(:params_without_address) do
      valid_params.merge(modality: "delivery")
    end

    it "returns failure due to validation" do
      result = travel_to(open_time) do
        described_class.call(user: customer, params: params_without_address)
      end
      expect(result).to be_failure
    end
  end
end
