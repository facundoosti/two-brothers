require "rails_helper"

RSpec.describe "Superadmin Tenants", type: :request do
  let(:valid_credentials) do
    username = "superadmin"
    password = "supersecret"
    ENV["SUPERADMIN_USERNAME"] = username
    ENV["SUPERADMIN_PASSWORD"] = password
    ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end

  let(:auth_headers) { { "HTTP_AUTHORIZATION" => valid_credentials } }

  before do
    # Stub Apartment to avoid actual schema creation/deletion
    allow(Apartment::Tenant).to receive(:create)
    allow(Apartment::Tenant).to receive(:drop)
    allow(TenantSeeder).to receive(:call)
  end

  # ─── GET /superadmin/tenants ─────────────────────────────────────────────

  describe "GET /superadmin/tenants" do
    let!(:tenant) { create(:tenant) }

    it "returns 200 with basic auth" do
      get "/superadmin/tenants", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 without basic auth" do
      get "/superadmin/tenants"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── GET /superadmin/tenants/new ─────────────────────────────────────────

  describe "GET /superadmin/tenants/new" do
    it "returns 200 with basic auth" do
      get "/superadmin/tenants/new", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # ─── POST /superadmin/tenants ─────────────────────────────────────────────

  describe "POST /superadmin/tenants" do
    let(:valid_params) { { tenant: { name: "Pollo Express", subdomain: "polloexpress" } } }

    it "creates a tenant and initializes schema" do
      expect {
        post "/superadmin/tenants", params: valid_params, headers: auth_headers
      }.to change(Tenant, :count).by(1)
      expect(Apartment::Tenant).to have_received(:create).with("polloexpress")
      expect(TenantSeeder).to have_received(:call).with("polloexpress", name: "Pollo Express")
    end

    it "redirects to tenants index on success" do
      post "/superadmin/tenants", params: valid_params, headers: auth_headers
      expect(response).to redirect_to("/superadmin/tenants")
    end

    it "renders new on invalid params" do
      post "/superadmin/tenants",
           params: { tenant: { name: "", subdomain: "" } },
           headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ─── GET /superadmin/tenants/:id/edit ────────────────────────────────────

  describe "GET /superadmin/tenants/:id/edit" do
    let!(:tenant) { create(:tenant) }

    it "returns 200 with basic auth" do
      get "/superadmin/tenants/#{tenant.id}/edit", headers: auth_headers
      expect(response).to have_http_status(:ok)
    end
  end

  # ─── PATCH /superadmin/tenants/:id ───────────────────────────────────────

  describe "PATCH /superadmin/tenants/:id" do
    let!(:tenant) { create(:tenant, name: "Old Name") }

    it "updates the tenant" do
      patch "/superadmin/tenants/#{tenant.id}",
            params: { tenant: { name: "New Name" } },
            headers: auth_headers
      expect(tenant.reload.name).to eq("New Name")
    end

    it "redirects on success" do
      patch "/superadmin/tenants/#{tenant.id}",
            params: { tenant: { name: "New Name" } },
            headers: auth_headers
      expect(response).to redirect_to("/superadmin/tenants")
    end

    it "renders edit on invalid params" do
      patch "/superadmin/tenants/#{tenant.id}",
            params: { tenant: { name: "", subdomain: "" } },
            headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ─── DELETE /superadmin/tenants/:id ──────────────────────────────────────

  describe "DELETE /superadmin/tenants/:id" do
    let!(:tenant) { create(:tenant) }

    it "destroys the tenant and drops the schema" do
      expect {
        delete "/superadmin/tenants/#{tenant.id}", headers: auth_headers
      }.to change(Tenant, :count).by(-1)
      expect(Apartment::Tenant).to have_received(:drop).with(tenant.subdomain)
    end

    it "redirects to tenants index" do
      delete "/superadmin/tenants/#{tenant.id}", headers: auth_headers
      expect(response).to redirect_to("/superadmin/tenants")
    end
  end
end
