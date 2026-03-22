require "rails_helper"

RSpec.describe "Dashboard API", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }

  describe "GET /api/v1/dashboard" do
    before { create(:daily_stock, date: Date.current, total: 100, used: 10) }

    it "returns dashboard stats for admin" do
      get "/api/v1/dashboard", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["orders"]).to be_present
      expect(json["stock"]).to be_present
      expect(json["active_orders"]).to be_an(Array)
    end

    it "returns correct stock data" do
      get "/api/v1/dashboard", headers: auth_headers(admin)
      json = JSON.parse(response.body)
      expect(json["stock"]["total"]).to eq(100)
      expect(json["stock"]["used"]).to eq(10)
      expect(json["stock"]["available"]).to eq(90)
    end

    it "returns order counts per status" do
      create(:order, :confirmed, user: create(:user))
      create(:order, :preparing, user: create(:user))

      get "/api/v1/dashboard", headers: auth_headers(admin)
      json = JSON.parse(response.body)
      expect(json["orders"]["confirmed"]).to be >= 1
      expect(json["orders"]["preparing"]).to be >= 1
    end

    it "includes active orders with the right fields" do
      order = create(:order, :confirmed, user: customer)
      create(:order, :confirmed, user: create(:user))  # ensure includes(:user) is exercised
      get "/api/v1/dashboard", headers: auth_headers(admin)
      json = JSON.parse(response.body)
      active = json["active_orders"].find { |o| o["id"] == order.id }
      expect(active).to be_present
      expect(active.keys).to include("id", "status", "modality", "customer_name", "total", "created_at")
    end

    it "returns 403 for non-admin" do
      get "/api/v1/dashboard", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      get "/api/v1/dashboard"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
