require "rails_helper"

RSpec.describe "Users API", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }

  # ─── GET /api/v1/me ──────────────────────────────────────────────────────

  describe "GET /api/v1/me" do
    it "returns the current user" do
      get "/api/v1/me", headers: auth_headers(customer)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(customer.id)
      expect(json["email"]).to eq(customer.email)
    end

    it "returns 401 when unauthenticated" do
      get "/api/v1/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── GET /api/v1/users ───────────────────────────────────────────────────

  describe "GET /api/v1/users" do
    let!(:delivery_user) { create(:user, :delivery, name: "Repartidor López") }
    let!(:other_customer) { create(:user, name: "Cliente García") }

    it "returns all users for admin" do
      get "/api/v1/users", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].length).to be >= 2
      expect(json["pagy"]).to be_present
    end

    it "filters by role" do
      get "/api/v1/users", params: { role: "delivery" }, headers: auth_headers(admin)
      json = JSON.parse(response.body)
      expect(json["data"].all? { |u| u["role"] == "delivery" }).to be true
    end

    it "filters by search query on name" do
      get "/api/v1/users", params: { q: "López" }, headers: auth_headers(admin)
      json = JSON.parse(response.body)
      ids = json["data"].map { |u| u["id"] }
      expect(ids).to include(delivery_user.id)
      expect(ids).not_to include(other_customer.id)
    end

    it "filters by search query on email" do
      get "/api/v1/users", params: { q: delivery_user.email }, headers: auth_headers(admin)
      json = JSON.parse(response.body)
      ids = json["data"].map { |u| u["id"] }
      expect(ids).to include(delivery_user.id)
    end

    it "returns 403 for non-admin" do
      get "/api/v1/users", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      get "/api/v1/users"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/users/:id ─────────────────────────────────────────────

  describe "PATCH /api/v1/users/:id" do
    let(:target_user) { create(:user) }

    it "updates role as admin" do
      patch "/api/v1/users/#{target_user.id}",
            params: { user: { role: "delivery" } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(target_user.reload.role).to eq("delivery")
    end

    it "updates status as admin" do
      target_user.update!(status: :active)
      patch "/api/v1/users/#{target_user.id}",
            params: { user: { status: "pending" } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(target_user.reload.status).to eq("pending")
    end

    it "returns 403 for non-admin" do
      patch "/api/v1/users/#{target_user.id}",
            params: { user: { role: "admin" } },
            headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      patch "/api/v1/users/#{target_user.id}", params: { user: { role: "delivery" } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/me ────────────────────────────────────────────────────

  describe "PATCH /api/v1/me" do
    it "updates the current user's default_address" do
      patch "/api/v1/me",
            params: { user: { default_address: "Av. Rivadavia 1234" } },
            headers: auth_headers(customer)
      expect(response).to have_http_status(:ok)
      expect(customer.reload.default_address).to eq("Av. Rivadavia 1234")
    end

    it "returns the updated user" do
      patch "/api/v1/me",
            params: { user: { default_address: "Mitre 500" } },
            headers: auth_headers(customer)
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(customer.id)
    end

    it "returns 401 when unauthenticated" do
      patch "/api/v1/me", params: { user: { default_address: "Fake" } }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
