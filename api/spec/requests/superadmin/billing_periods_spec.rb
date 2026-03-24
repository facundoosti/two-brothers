require "rails_helper"

RSpec.describe "Superadmin Billing Periods", type: :request do
  let(:valid_credentials) do
    ENV["SUPERADMIN_USERNAME"] = "superadmin"
    ENV["SUPERADMIN_PASSWORD"] = "supersecret"
    ActionController::HttpAuthentication::Basic.encode_credentials("superadmin", "supersecret")
  end
  let(:auth_headers) { { "HTTP_AUTHORIZATION" => valid_credentials } }

  let(:tenant)       { create(:tenant) }
  let(:subscription) { create(:subscription, tenant: tenant, started_at: 3.months.ago.to_date) }
  let!(:bp)          { create(:billing_period, subscription: subscription) }

  before do
    allow(Apartment::Tenant).to receive(:switch).and_yield
    allow(Order).to receive_message_chain(:where, :where, :sum).and_return(0)
  end

  # ─── GET /superadmin/billing_periods ─────────────────────────────────────

  describe "GET /superadmin/billing_periods" do
    it "returns 200 with valid auth" do
      get "/superadmin/billing_periods", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without auth" do
      get "/superadmin/billing_periods"
      expect(response).to have_http_status(:unauthorized)
    end

    it "filters by tenant_id" do
      get "/superadmin/billing_periods", params: { tenant_id: tenant.id }, headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it "filters by year" do
      get "/superadmin/billing_periods", params: { year: bp.year }, headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it "filters by month" do
      get "/superadmin/billing_periods", params: { month: bp.month }, headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      get "/superadmin/billing_periods", params: { status: "pending" }, headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # ─── GET /superadmin/billing_periods/:id ─────────────────────────────────

  describe "GET /superadmin/billing_periods/:id" do
    it "returns 200" do
      get "/superadmin/billing_periods/#{bp.id}", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # ─── PATCH /superadmin/billing_periods/:id/mark_paid ─────────────────────

  describe "PATCH /superadmin/billing_periods/:id/mark_paid" do
    it "marks a pending period as paid" do
      patch "/superadmin/billing_periods/#{bp.id}/mark_paid", headers: auth_headers
      expect(bp.reload.status).to eq("paid")
    end

    it "redirects to the billing period detail" do
      patch "/superadmin/billing_periods/#{bp.id}/mark_paid", headers: auth_headers
      expect(response).to redirect_to("/superadmin/billing_periods/#{bp.id}")
    end

    it "redirects with alert if already paid" do
      bp.update!(status: :paid)
      patch "/superadmin/billing_periods/#{bp.id}/mark_paid", headers: auth_headers
      expect(response).to redirect_to("/superadmin/billing_periods/#{bp.id}")
      expect(flash[:alert]).to be_present
    end
  end

  # ─── POST /superadmin/billing_periods/generate ───────────────────────────

  describe "POST /superadmin/billing_periods/generate" do
    let(:year)  { Date.today.prev_month.year }
    let(:month) { Date.today.prev_month.month }

    before { create(:exchange_rate, year: year, month: month) }

    it "generates billing periods for active subscriptions" do
      # Remove existing bp to allow generation
      bp.destroy
      expect {
        post "/superadmin/billing_periods/generate",
             params: { year: year, month: month },
             headers: auth_headers
      }.to change(BillingPeriod, :count).by(1)
    end

    it "redirects to index with notice" do
      bp.destroy
      post "/superadmin/billing_periods/generate",
           params: { year: year, month: month },
           headers: auth_headers
      expect(response).to redirect_to("/superadmin/billing_periods")
      expect(flash[:notice]).to include("generado")
    end

    it "redirects with alert on invalid year/month" do
      post "/superadmin/billing_periods/generate",
           params: { year: 2019, month: 1 },
           headers: auth_headers
      expect(response).to redirect_to("/superadmin/billing_periods")
      expect(flash[:alert]).to include("inválido")
    end

    it "includes errors in notice when period already exists" do
      post "/superadmin/billing_periods/generate",
           params: { year: bp.year, month: bp.month },
           headers: auth_headers
      expect(response).to redirect_to("/superadmin/billing_periods")
      expect(flash[:notice]).to include("ya existe")
    end
  end
end
