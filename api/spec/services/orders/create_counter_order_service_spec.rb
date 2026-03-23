require "rails_helper"

RSpec.describe Orders::CreateCounterOrderService, type: :service do
  let(:admin)     { create(:user, :admin) }
  let(:category)  { create(:category) }
  let(:menu_item) { create(:menu_item, category: category) }
  let!(:stock)    { create(:daily_stock, date: Date.current, total: 100, used: 0) }

  let(:valid_params) do
    {
      payment_method: "cash",
      order_items_attributes: [
        { menu_item_id: menu_item.id, quantity: 2, unit_price: 1500.00 }
      ]
    }
  end

  subject(:result) { described_class.call(admin: admin, params: valid_params) }

  describe "successful counter order" do
    it "returns a success result" do
      expect(result).to be_success
    end

    it "creates an order with pickup modality" do
      expect { result }.to change(Order, :count).by(1)
      expect(result.payload.modality).to eq("pickup")
    end

    it "transitions the order directly to confirmed" do
      expect(result.payload.status).to eq("confirmed")
    end

    it "sets created_by to the admin" do
      expect(result.payload.created_by).to eq(admin)
    end

    it "deducts stock" do
      result
      expect(stock.reload.used).to eq(2)
    end

    it "sets confirmed_at timestamp" do
      expect(result.payload.confirmed_at).to be_present
    end
  end

  describe "max chickens validation" do
    let(:over_limit_params) do
      {
        payment_method: "cash",
        order_items_attributes: [
          { menu_item_id: menu_item.id, quantity: 5, unit_price: 1500.00 }
        ]
      }
    end

    it "returns failure when quantity exceeds 4" do
      result = described_class.call(admin: admin, params: over_limit_params)
      expect(result).not_to be_success
      expect(result.error).to be_present
    end

    it "does not create an order" do
      expect {
        described_class.call(admin: admin, params: over_limit_params)
      }.not_to change(Order, :count)
    end

    it "does not deduct stock" do
      described_class.call(admin: admin, params: over_limit_params)
      expect(stock.reload.used).to eq(0)
    end
  end

  describe "insufficient stock" do
    let!(:stock) { create(:daily_stock, date: Date.current, total: 100, used: 99) }

    it "returns failure" do
      result = described_class.call(admin: admin, params: valid_params)
      expect(result).not_to be_success
      expect(result.error).to be_present
    end

    it "does not create an order" do
      expect {
        described_class.call(admin: admin, params: valid_params)
      }.not_to change(Order, :count)
    end
  end

  describe "multiple order items" do
    let(:menu_item2) { create(:menu_item, category: category) }
    let(:multi_params) do
      {
        payment_method: "cash",
        order_items_attributes: [
          { menu_item_id: menu_item.id, quantity: 1, unit_price: 1500.00 },
          { menu_item_id: menu_item2.id, quantity: 1, unit_price: 2000.00 }
        ]
      }
    end

    it "creates the order with both items" do
      result = described_class.call(admin: admin, params: multi_params)
      expect(result).to be_success
      expect(result.payload.order_items.count).to eq(2)
    end

    it "deducts the total quantity (2 chickens)" do
      described_class.call(admin: admin, params: multi_params)
      expect(stock.reload.used).to eq(2)
    end
  end
end
