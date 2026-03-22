require "rails_helper"

RSpec.describe "Settings API", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }

  before do
    Setting["daily_chicken_stock"] = "100"
    Setting["store_name"] = "Two Brothers"
  end

  # ─── GET /api/v1/settings ────────────────────────────────────────────────

  describe "GET /api/v1/settings" do
    it "returns all allowed settings for admin" do
      get "/api/v1/settings", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      keys = json.map { |s| s["key"] }
      expect(keys).to include("daily_chicken_stock", "store_name")
    end

    it "returns nil value for settings not yet configured" do
      get "/api/v1/settings", headers: auth_headers(admin)
      json = JSON.parse(response.body)
      unconfigured = json.find { |s| s["key"] == "mp_alias" }
      expect(unconfigured["value"]).to be_nil
    end

    it "returns 403 for non-admin" do
      get "/api/v1/settings", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      get "/api/v1/settings"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/settings ──────────────────────────────────────────────

  describe "PATCH /api/v1/settings" do
    it "updates allowed settings and returns 204" do
      patch "/api/v1/settings",
            params: { settings: { daily_chicken_stock: "80", store_name: "Los Hermanos" } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:no_content)
      expect(Setting["daily_chicken_stock"]).to eq("80")
      expect(Setting["store_name"]).to eq("Los Hermanos")
    end

    it "ignores disallowed keys" do
      patch "/api/v1/settings",
            params: { settings: { secret_key: "hacked", store_name: "New Name" } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:no_content)
      expect(Setting["secret_key"]).to be_nil
    end

    it "returns 403 for non-admin" do
      patch "/api/v1/settings",
            params: { settings: { store_name: "Hack" } },
            headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      patch "/api/v1/settings", params: { settings: { store_name: "Hack" } }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
