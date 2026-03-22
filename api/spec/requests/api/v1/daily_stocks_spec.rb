require "rails_helper"

RSpec.describe "Daily Stocks API", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }

  # ─── GET /api/v1/daily_stock ─────────────────────────────────────────────

  describe "GET /api/v1/daily_stock" do
    before { create(:daily_stock, date: Date.current, total: 80, used: 20) }

    it "returns today's stock for admin" do
      get "/api/v1/daily_stock", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["total"]).to eq(80)
      expect(json["used"]).to eq(20)
    end

    it "creates stock for today if it does not exist" do
      DailyStock.where(date: Date.current).delete_all
      expect {
        get "/api/v1/daily_stock", headers: auth_headers(admin)
      }.to change(DailyStock, :count).by(1)
      expect(response).to have_http_status(:ok)
    end

    it "returns 403 for non-admin" do
      get "/api/v1/daily_stock", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      get "/api/v1/daily_stock"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/daily_stock ───────────────────────────────────────────

  describe "PATCH /api/v1/daily_stock" do
    before { create(:daily_stock, date: Date.current, total: 80, used: 0) }

    it "updates total for admin" do
      patch "/api/v1/daily_stock", params: { total: 120 }, headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["total"]).to eq(120)
    end

    it "returns error for invalid total" do
      patch "/api/v1/daily_stock", params: { total: -5 }, headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for non-admin" do
      patch "/api/v1/daily_stock", params: { total: 50 }, headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      patch "/api/v1/daily_stock", params: { total: 50 }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
