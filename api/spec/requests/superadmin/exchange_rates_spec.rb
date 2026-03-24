require "rails_helper"

RSpec.describe "Superadmin Exchange Rates", type: :request do
  let(:valid_credentials) do
    ENV["SUPERADMIN_USERNAME"] = "superadmin"
    ENV["SUPERADMIN_PASSWORD"] = "supersecret"
    ActionController::HttpAuthentication::Basic.encode_credentials("superadmin", "supersecret")
  end
  let(:auth_headers) { { "HTTP_AUTHORIZATION" => valid_credentials } }

  # ─── GET /superadmin/exchange_rates ──────────────────────────────────────

  describe "GET /superadmin/exchange_rates" do
    let!(:rate) { create(:exchange_rate) }

    it "returns 200 with valid auth" do
      get "/superadmin/exchange_rates", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without auth" do
      get "/superadmin/exchange_rates"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── POST /superadmin/exchange_rates ─────────────────────────────────────

  describe "POST /superadmin/exchange_rates" do
    let(:valid_params) { { exchange_rate: { year: 2026, month: 5, blue_rate: 1500.0 } } }

    it "creates a new exchange rate" do
      expect {
        post "/superadmin/exchange_rates", params: valid_params, headers: auth_headers
      }.to change(ExchangeRate, :count).by(1)
    end

    it "redirects to index on success" do
      post "/superadmin/exchange_rates", params: valid_params, headers: auth_headers
      expect(response).to redirect_to("/superadmin/exchange_rates")
    end

    it "renders index with errors on duplicate year/month" do
      create(:exchange_rate, year: 2026, month: 5)
      post "/superadmin/exchange_rates", params: valid_params, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "renders index with errors when blue_rate is missing" do
      post "/superadmin/exchange_rates",
           params: { exchange_rate: { year: 2026, month: 6, blue_rate: "" } },
           headers: auth_headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  # ─── GET /superadmin/exchange_rates/:id/edit ─────────────────────────────

  describe "GET /superadmin/exchange_rates/:id/edit" do
    let!(:rate) { create(:exchange_rate) }

    it "returns 200" do
      get "/superadmin/exchange_rates/#{rate.id}/edit", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # ─── PATCH /superadmin/exchange_rates/:id ────────────────────────────────

  describe "PATCH /superadmin/exchange_rates/:id" do
    let!(:rate) { create(:exchange_rate, blue_rate: 1000.0) }

    it "updates the blue_rate" do
      patch "/superadmin/exchange_rates/#{rate.id}",
            params: { exchange_rate: { blue_rate: 1500.0 } },
            headers: auth_headers
      expect(rate.reload.blue_rate).to eq(1500.0)
    end

    it "redirects to index on success" do
      patch "/superadmin/exchange_rates/#{rate.id}",
            params: { exchange_rate: { blue_rate: 1500.0 } },
            headers: auth_headers
      expect(response).to redirect_to("/superadmin/exchange_rates")
    end

    it "renders edit on invalid params" do
      patch "/superadmin/exchange_rates/#{rate.id}",
            params: { exchange_rate: { blue_rate: -1 } },
            headers: auth_headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
