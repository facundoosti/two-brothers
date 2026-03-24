require "rails_helper"

RSpec.describe Orders::CreateCounterOrderService, type: :service do
  let(:admin)     { create(:user, :admin) }
  let(:category)  { create(:category) }
  let(:menu_item) { create(:menu_item, category: category, daily_stock: 50) }

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

    it "deducts stock for each item" do
      stock = DailyStock.for_item_today(menu_item)
      used_before = stock.used

      result

      expect(stock.reload.used).to eq(used_before + 2)
    end

    it "sets confirmed_at timestamp" do
      expect(result.payload.confirmed_at).to be_present
    end
  end

  describe "max quantity per item exceeded" do
    let(:over_limit_params) do
      {
        payment_method: "cash",
        order_items_attributes: [
          { menu_item_id: menu_item.id, quantity: 11, unit_price: 1500.00 }
        ]
      }
    end

    it "returns failure" do
      result = described_class.call(admin: admin, params: over_limit_params)
      expect(result).not_to be_success
      expect(result.error).to eq(I18n.t("errors.max_quantity_per_item", max: 10))
    end

    it "does not create an order" do
      expect {
        described_class.call(admin: admin, params: over_limit_params)
      }.not_to change(Order, :count)
    end

    it "does not deduct stock" do
      stock = DailyStock.for_item_today(menu_item)
      described_class.call(admin: admin, params: over_limit_params)
      expect(stock.reload.used).to eq(0)
    end
  end

  describe "item without daily stock configured" do
    let(:menu_item) { create(:menu_item, :no_stock, category: category) }

    it "returns failure" do
      result = described_class.call(admin: admin, params: valid_params)
      expect(result).not_to be_success
      expect(result.error).to include(I18n.t("errors.item_no_stock", name: menu_item.name))
    end
  end

  describe "insufficient stock for item" do
    before do
      stock = DailyStock.for_item_today(menu_item)
      stock.update!(used: 49) # only 1 available, but requesting 2
    end

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
    let(:menu_item2) { create(:menu_item, category: category, daily_stock: 50) }
    let(:multi_params) do
      {
        payment_method: "cash",
        order_items_attributes: [
          { menu_item_id: menu_item.id,  quantity: 1, unit_price: 1500.00 },
          { menu_item_id: menu_item2.id, quantity: 1, unit_price: 2000.00 }
        ]
      }
    end

    it "creates the order with both items" do
      result = described_class.call(admin: admin, params: multi_params)
      expect(result).to be_success
      expect(result.payload.order_items.count).to eq(2)
    end

    it "deducts stock per item independently" do
      stock1 = DailyStock.for_item_today(menu_item)
      stock2 = DailyStock.for_item_today(menu_item2)

      described_class.call(admin: admin, params: multi_params)

      expect(stock1.reload.used).to eq(1)
      expect(stock2.reload.used).to eq(1)
    end
  end
end
