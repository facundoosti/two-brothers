require "rails_helper"

RSpec.describe "Daily Stocks API", type: :request do
  let(:admin)     { create(:user, :admin) }
  let(:customer)  { create(:user) }
  let(:menu_item) { create(:menu_item, daily_stock: 80) }

  # ─── GET /api/v1/daily_stocks ────────────────────────────────────────────────

  describe "GET /api/v1/daily_stocks" do
    before { create(:daily_stock, menu_item: menu_item, date: Date.current, total: 80, used: 20) }

    it "returns today's stock for admin" do
      get "/api/v1/daily_stocks", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      entry = json.find { |s| s["menu_item_id"] == menu_item.id }
      expect(entry["total"]).to eq(80)
      expect(entry["used"]).to eq(20)
      expect(entry["available"]).to eq(60)
    end

    it "auto-creates stock records for items that don't have one yet" do
      DailyStock.where(menu_item: menu_item, date: Date.current).delete_all
      expect {
        get "/api/v1/daily_stocks", headers: auth_headers(admin)
      }.to change(DailyStock, :count).by(1)
      expect(response).to have_http_status(:ok)
    end

    it "returns 403 for non-admin" do
      get "/api/v1/daily_stocks", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      get "/api/v1/daily_stocks"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/daily_stocks/:id ──────────────────────────────────────────

  describe "PATCH /api/v1/daily_stocks/:id" do
    let!(:stock) { create(:daily_stock, menu_item: menu_item, date: Date.current, total: 80, used: 0) }

    it "updates total for admin" do
      patch "/api/v1/daily_stocks/#{stock.id}", params: { total: 120 }, headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["total"]).to eq(120)
    end

    it "returns error for invalid total" do
      patch "/api/v1/daily_stocks/#{stock.id}", params: { total: -5 }, headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for non-admin" do
      patch "/api/v1/daily_stocks/#{stock.id}", params: { total: 50 }, headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      patch "/api/v1/daily_stocks/#{stock.id}", params: { total: 50 }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
