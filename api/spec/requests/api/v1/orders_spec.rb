require "rails_helper"

RSpec.describe "Orders API", type: :request do
  let(:customer)  { create(:user) }
  let(:admin)     { create(:user, :admin) }
  let(:category)  { create(:category) }
  let(:menu_item) { create(:menu_item, category: category) }

  # ─── GET /api/v1/orders ───────────────────────────────────────────────────

  describe "GET /api/v1/orders" do
    context "as customer" do
      let!(:my_order)    { create(:order, user: customer) }
      let!(:other_order) { create(:order) }

      it "returns only own orders" do
        get "/api/v1/orders", headers: auth_headers(customer)
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        ids = json["data"].map { |o| o["id"] }
        expect(ids).to include(my_order.id)
        expect(ids).not_to include(other_order.id)
      end
    end

    context "as admin" do
      let!(:order1) { create(:order) }
      let!(:order2) { create(:order, :confirmed) }

      it "returns all orders" do
        get "/api/v1/orders", headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to be >= 2
      end

      it "filters by status" do
        get "/api/v1/orders", params: { status: "confirmed" }, headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["data"].all? { |o| o["status"] == "confirmed" }).to be true
      end
    end

    context "unauthenticated" do
      it "returns 401" do
        get "/api/v1/orders"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # ─── GET /api/v1/orders/:id ───────────────────────────────────────────────

  describe "GET /api/v1/orders/:id" do
    let(:order) { create(:order, user: customer) }

    it "returns the order for its owner" do
      get "/api/v1/orders/#{order.id}", headers: auth_headers(customer)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(order.id)
    end

    it "returns the order for an admin" do
      get "/api/v1/orders/#{order.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
    end

    it "returns 403 for another customer" do
      other = create(:user)
      get "/api/v1/orders/#{order.id}", headers: auth_headers(other)
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ─── POST /api/v1/orders ─────────────────────────────────────────────────

  describe "POST /api/v1/orders" do
    # Thursday 20:30 Buenos Aires (23:30 UTC) — within business hours, same UTC date as the stock fixture
    let(:open_time) { Time.find_zone("America/Argentina/Buenos_Aires").local(2026, 3, 19, 20, 30, 0) }

    before { create(:daily_stock, date: Date.new(2026, 3, 19), total: 100, used: 0) }

    let(:valid_params) do
      {
        order: {
          modality:       "pickup",
          payment_method: "cash",
          order_items_attributes: [
            { menu_item_id: menu_item.id, quantity: 1, unit_price: 1500.00 }
          ]
        }
      }
    end

    it "creates an order during business hours" do
      travel_to(open_time) do
        expect {
          post "/api/v1/orders", params: valid_params, headers: auth_headers(customer)
        }.to change(Order, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    it "returns error outside business hours" do
      travel_to(Time.find_zone("America/Argentina/Buenos_Aires").local(2026, 3, 19, 10, 0, 0)) do
        post "/api/v1/orders", params: valid_params, headers: auth_headers(customer)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it "returns 401 when unauthenticated" do
      post "/api/v1/orders", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/orders/:id/confirm_payment ─────────────────────────────

  describe "PATCH /api/v1/orders/:id/confirm_payment" do
    let!(:stock) { create(:daily_stock, date: Date.current, total: 100, used: 0) }
    let(:order)  { create(:order, :with_item) }

    it "confirms payment as admin" do
      patch "/api/v1/orders/#{order.id}/confirm_payment", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(order.reload).to be_confirmed
    end

    it "returns 403 for customer" do
      patch "/api/v1/orders/#{order.id}/confirm_payment", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ─── PATCH /api/v1/orders/:id/status ─────────────────────────────────────

  describe "PATCH /api/v1/orders/:id/status" do
    let(:order) { create(:order, :confirmed) }

    it "advances order to preparing as admin" do
      patch "/api/v1/orders/#{order.id}/status",
            params: { status: "preparing" },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(order.reload).to be_preparing
    end

    it "returns error for invalid status" do
      patch "/api/v1/orders/#{order.id}/status",
            params: { status: "nonexistent" },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for customer" do
      patch "/api/v1/orders/#{order.id}/status",
            params: { status: "preparing" },
            headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ─── PATCH /api/v1/orders/:id/cancel ─────────────────────────────────────

  describe "PATCH /api/v1/orders/:id/cancel" do
    let!(:stock) { create(:daily_stock, date: Date.current, total: 100, used: 0) }
    let(:order)  { create(:order) }

    it "cancels order as admin" do
      patch "/api/v1/orders/#{order.id}/cancel",
            params: { cancellation_reason: "Customer changed mind" },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(order.reload).to be_cancelled
    end

    it "returns error if order cannot be cancelled" do
      order = create(:order, :preparing)
      patch "/api/v1/orders/#{order.id}/cancel", headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for customer" do
      patch "/api/v1/orders/#{order.id}/cancel", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ─── POST /api/v1/orders/counter ─────────────────────────────────────────

  describe "POST /api/v1/orders/counter" do
    let!(:stock) { create(:daily_stock, date: Date.current, total: 100, used: 0) }

    let(:valid_params) do
      {
        order: {
          payment_method: "cash",
          order_items_attributes: [
            { menu_item_id: menu_item.id, quantity: 2, unit_price: 1500.00 }
          ]
        }
      }
    end

    it "creates a counter order as admin" do
      expect {
        post "/api/v1/orders/counter", params: valid_params, headers: auth_headers(admin)
      }.to change(Order, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "returns the order in confirmed status" do
      post "/api/v1/orders/counter", params: valid_params, headers: auth_headers(admin)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("confirmed")
    end

    it "returns pickup modality" do
      post "/api/v1/orders/counter", params: valid_params, headers: auth_headers(admin)
      json = JSON.parse(response.body)
      expect(json["modality"]).to eq("pickup")
    end

    it "deducts stock" do
      post "/api/v1/orders/counter", params: valid_params, headers: auth_headers(admin)
      expect(stock.reload.used).to eq(2)
    end

    it "returns error when quantity exceeds 4 chickens" do
      over_limit = { order: { payment_method: "cash", order_items_attributes: [{ menu_item_id: menu_item.id, quantity: 5, unit_price: 1500.00 }] } }
      post "/api/v1/orders/counter", params: over_limit, headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns error when stock is insufficient" do
      stock.update!(used: 100)
      post "/api/v1/orders/counter", params: valid_params, headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for customer" do
      post "/api/v1/orders/counter", params: valid_params, headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      post "/api/v1/orders/counter", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── GET /api/v1/orders — modality filter ────────────────────────────────

  describe "GET /api/v1/orders — modality filter" do
    let!(:pickup_order)   { create(:order, user: admin, modality: :pickup) }
    let!(:delivery_order) { create(:order, :delivery, user: admin) }

    it "filters by modality as admin" do
      get "/api/v1/orders", params: { modality: "pickup" }, headers: auth_headers(admin)
      json = JSON.parse(response.body)
      expect(json["data"].all? { |o| o["modality"] == "pickup" }).to be true
    end
  end
end
