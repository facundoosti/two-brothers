require "rails_helper"

RSpec.describe "Categories API", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }

  # ─── GET /api/v1/categories ──────────────────────────────────────────────

  describe "GET /api/v1/categories" do
    let!(:category)  { create(:category, name: "Pollos", position: 1) }
    let!(:menu_item) { create(:menu_item, category: category, name: "Pollo entero") }

    it "is accessible without authentication" do
      get "/api/v1/categories"
      expect(response).to have_http_status(:ok)
    end

    it "returns all categories with their items" do
      get "/api/v1/categories"
      json = JSON.parse(response.body)
      expect(json.length).to be >= 1
      expect(json.first["name"]).to eq("Pollos")
    end

    it "includes menu_items in the response" do
      get "/api/v1/categories"
      json = JSON.parse(response.body)
      category_data = json.find { |c| c["id"] == category.id }
      expect(category_data["menu_items"]).to be_present
      expect(category_data["menu_items"].first["name"]).to eq("Pollo entero")
    end
  end

  # ─── POST /api/v1/categories ─────────────────────────────────────────────

  describe "POST /api/v1/categories" do
    let(:valid_params) { { category: { name: "Bebidas", position: 2 } } }

    it "creates a category as admin" do
      expect {
        post "/api/v1/categories", params: valid_params, headers: auth_headers(admin)
      }.to change(Category, :count).by(1)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Bebidas")
    end

    it "returns error for missing name" do
      post "/api/v1/categories",
           params: { category: { position: 1 } },
           headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for non-admin" do
      post "/api/v1/categories", params: valid_params, headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      post "/api/v1/categories", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/categories/:id ────────────────────────────────────────

  describe "PATCH /api/v1/categories/:id" do
    let!(:category) { create(:category, name: "Pollos", position: 1) }

    it "updates a category as admin" do
      patch "/api/v1/categories/#{category.id}",
            params: { category: { name: "Acompañamientos", position: 3 } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(category.reload.name).to eq("Acompañamientos")
    end

    it "returns error for invalid position" do
      patch "/api/v1/categories/#{category.id}",
            params: { category: { position: -1 } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for non-admin" do
      patch "/api/v1/categories/#{category.id}",
            params: { category: { name: "Hack" } },
            headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ─── DELETE /api/v1/categories/:id ───────────────────────────────────────

  describe "DELETE /api/v1/categories/:id" do
    let!(:category) { create(:category) }

    it "deletes a category as admin" do
      expect {
        delete "/api/v1/categories/#{category.id}", headers: auth_headers(admin)
      }.to change(Category, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "returns 403 for non-admin" do
      delete "/api/v1/categories/#{category.id}", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      delete "/api/v1/categories/#{category.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
