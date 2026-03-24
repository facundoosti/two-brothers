require "rails_helper"

RSpec.describe "Store Status API", type: :request do
  before { Setting.delete_all }

  describe "GET /api/v1/store_status" do
    it "is accessible without authentication" do
      get "/api/v1/store_status"
      expect(response).to have_http_status(:ok)
    end

    it "returns the expected fields" do
      get "/api/v1/store_status"
      json = JSON.parse(response.body)
      expect(json.keys).to include("open", "stock_available", "opening_time", "closing_time", "open_days", "delivery_fee", "delivery_fee_enabled")
    end

    it "returns default opening_time of 20:00" do
      get "/api/v1/store_status"
      json = JSON.parse(response.body)
      expect(json["opening_time"]).to eq("20:00")
    end

    it "returns default closing_time of 00:00" do
      get "/api/v1/store_status"
      json = JSON.parse(response.body)
      expect(json["closing_time"]).to eq("00:00")
    end

    it "returns default open_days [4, 5, 6, 0]" do
      get "/api/v1/store_status"
      json = JSON.parse(response.body)
      expect(json["open_days"]).to eq([4, 5, 6, 0])
    end

    it "returns default delivery_fee of 0" do
      get "/api/v1/store_status"
      json = JSON.parse(response.body)
      expect(json["delivery_fee"]).to eq(0.0)
    end

    it "returns delivery_fee_enabled as false by default" do
      get "/api/v1/store_status"
      json = JSON.parse(response.body)
      expect(json["delivery_fee_enabled"]).to be false
    end

    context "with custom settings" do
      before do
        Setting["opening_time"]         = "19:00"
        Setting["closing_time"]         = "23:00"
        Setting["open_days"]            = "1,2,3"
        Setting["delivery_fee"]         = "500"
        Setting["delivery_fee_enabled"] = "true"
      end

      it "returns custom opening_time" do
        get "/api/v1/store_status"
        expect(JSON.parse(response.body)["opening_time"]).to eq("19:00")
      end

      it "returns custom closing_time" do
        get "/api/v1/store_status"
        expect(JSON.parse(response.body)["closing_time"]).to eq("23:00")
      end

      it "returns custom open_days as integers" do
        get "/api/v1/store_status"
        expect(JSON.parse(response.body)["open_days"]).to eq([1, 2, 3])
      end

      it "returns custom delivery_fee" do
        get "/api/v1/store_status"
        expect(JSON.parse(response.body)["delivery_fee"]).to eq(500.0)
      end

      it "returns delivery_fee_enabled as true" do
        get "/api/v1/store_status"
        expect(JSON.parse(response.body)["delivery_fee_enabled"]).to be true
      end
    end

    it "returns stock_available true when items with daily_stock exist" do
      create(:menu_item, available: true, daily_stock: 50)
      get "/api/v1/store_status"
      json = JSON.parse(response.body)
      expect(json["stock_available"]).to be true
    end

    it "returns stock_available false when no items have daily_stock configured" do
      MenuItem.delete_all
      get "/api/v1/store_status"
      json = JSON.parse(response.body)
      expect(json["stock_available"]).to be false
    end
  end
end
