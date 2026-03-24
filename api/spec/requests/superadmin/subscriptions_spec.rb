require "rails_helper"

RSpec.describe "Superadmin Subscriptions", type: :request do
  let(:valid_credentials) do
    ENV["SUPERADMIN_USERNAME"] = "superadmin"
    ENV["SUPERADMIN_PASSWORD"] = "supersecret"
    ActionController::HttpAuthentication::Basic.encode_credentials("superadmin", "supersecret")
  end
  let(:auth_headers) { { "HTTP_AUTHORIZATION" => valid_credentials } }

  # ─── GET /superadmin/subscriptions ───────────────────────────────────────

  describe "GET /superadmin/subscriptions" do
    let!(:subscription) { create(:subscription) }

    it "returns 200 with valid auth" do
      get "/superadmin/subscriptions", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without auth" do
      get "/superadmin/subscriptions"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── POST /superadmin/subscriptions ──────────────────────────────────────

  describe "POST /superadmin/subscriptions" do
    let(:tenant) { create(:tenant) }

    it "creates a subscription for the tenant" do
      expect {
        post "/superadmin/subscriptions",
             params: { subscription: { tenant_id: tenant.id, started_at: Date.today } },
             headers: auth_headers
      }.to change(Subscription, :count).by(1)
    end

    it "redirects to index on success" do
      post "/superadmin/subscriptions",
           params: { subscription: { tenant_id: tenant.id, started_at: Date.today } },
           headers: auth_headers
      expect(response).to redirect_to("/superadmin/subscriptions")
    end

    it "renders index with errors when tenant already has an active subscription" do
      create(:subscription, tenant: tenant, status: :active)
      post "/superadmin/subscriptions",
           params: { subscription: { tenant_id: tenant.id, started_at: Date.today } },
           headers: auth_headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  # ─── PATCH /superadmin/subscriptions/:id/suspend ─────────────────────────

  describe "PATCH /superadmin/subscriptions/:id/suspend" do
    let!(:subscription) { create(:subscription, status: :active) }

    it "suspends an active subscription" do
      patch "/superadmin/subscriptions/#{subscription.id}/suspend", headers: auth_headers
      expect(subscription.reload.status).to eq("suspended")
    end

    it "redirects to index" do
      patch "/superadmin/subscriptions/#{subscription.id}/suspend", headers: auth_headers
      expect(response).to redirect_to("/superadmin/subscriptions")
    end

    it "redirects with alert if already suspended" do
      subscription.update!(status: :suspended)
      patch "/superadmin/subscriptions/#{subscription.id}/suspend", headers: auth_headers
      expect(response).to redirect_to("/superadmin/subscriptions")
      expect(flash[:alert]).to be_present
    end
  end

  # ─── PATCH /superadmin/subscriptions/:id/reactivate ──────────────────────

  describe "PATCH /superadmin/subscriptions/:id/reactivate" do
    let!(:subscription) { create(:subscription, :suspended) }

    it "reactivates a suspended subscription" do
      patch "/superadmin/subscriptions/#{subscription.id}/reactivate", headers: auth_headers
      expect(subscription.reload.status).to eq("active")
    end

    it "redirects to index" do
      patch "/superadmin/subscriptions/#{subscription.id}/reactivate", headers: auth_headers
      expect(response).to redirect_to("/superadmin/subscriptions")
    end

    it "redirects with alert if already active" do
      subscription.update!(status: :active)
      patch "/superadmin/subscriptions/#{subscription.id}/reactivate", headers: auth_headers
      expect(response).to redirect_to("/superadmin/subscriptions")
      expect(flash[:alert]).to be_present
    end
  end
end
