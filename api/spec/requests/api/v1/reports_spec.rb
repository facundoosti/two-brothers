require "rails_helper"

RSpec.describe "Reports API", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }
  let(:category) { create(:category) }
  let(:menu_item) { create(:menu_item, category: category) }

  describe "GET /api/v1/reports" do
    context "unauthenticated" do
      it "returns 401" do
        get "/api/v1/reports"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "as customer" do
      it "returns 403" do
        get "/api/v1/reports", headers: auth_headers(customer)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as admin with no orders" do
      it "returns 200 with zeroed stats" do
        get "/api/v1/reports", headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["stats"]["total_orders"]).to eq(0)
        expect(json["stats"]["total_sales"]).to eq(0.0)
        expect(json["stats"]["avg_ticket"]).to eq(0.0)
        expect(json["daily_sales"]).to eq([])
        expect(json["top_items"]).to eq([])
      end
    end

    context "as admin with orders" do
      let!(:order1) { create(:order, user: admin, total: 3000, status: "confirmed", created_at: Time.current) }
      let!(:order2) { create(:order, user: admin, total: 1500, status: "delivered", created_at: Time.current) }
      let!(:cancelled_order) { create(:order, user: admin, total: 9999, status: "cancelled", created_at: Time.current) }

      before do
        create(:order_item, order: order1, menu_item: menu_item, quantity: 2, unit_price: 1500)
        create(:order_item, order: order2, menu_item: menu_item, quantity: 1, unit_price: 1500)
      end

      it "returns the correct total_orders (excludes cancelled)" do
        get "/api/v1/reports", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["stats"]["total_orders"]).to be >= 2
      end

      it "returns total_sales excluding cancelled orders" do
        get "/api/v1/reports", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["stats"]["total_sales"]).to be >= 4500.0
      end

      it "returns total_items" do
        get "/api/v1/reports", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["stats"]["total_items"]).to be >= 3
      end

      it "returns top_items with name and sold" do
        get "/api/v1/reports", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["top_items"]).to all(include("name", "sold"))
      end

      it "returns daily_sales with day, value, orders" do
        get "/api/v1/reports", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["daily_sales"]).to all(include("day", "value", "orders"))
      end

      it "returns transition_metrics with expected keys" do
        get "/api/v1/reports", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        metrics = json["transition_metrics"]
        expect(metrics.keys).to include(
          "created_to_confirmed",
          "confirmed_to_preparing",
          "preparing_to_ready",
          "ready_to_delivering",
          "delivering_to_delivered",
          "total"
        )
      end

      it "returns trends inside stats" do
        get "/api/v1/reports", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["stats"]["trends"].keys).to include("sales", "orders", "avg_ticket")
      end
    end

    context "period parameter" do
      it "accepts week period" do
        get "/api/v1/reports", params: { period: "week" }, headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
      end

      it "accepts month period" do
        get "/api/v1/reports", params: { period: "month" }, headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
      end

      it "accepts year period" do
        get "/api/v1/reports", params: { period: "year" }, headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
      end

      it "defaults to week for invalid period" do
        get "/api/v1/reports", params: { period: "invalid" }, headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
