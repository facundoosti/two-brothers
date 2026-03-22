require "rails_helper"

RSpec.describe "Menu Items API", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:customer) { create(:user) }
  let(:category) { create(:category) }

  # ─── POST /api/v1/menu_items ─────────────────────────────────────────────

  describe "POST /api/v1/menu_items" do
    let(:valid_params) do
      { menu_item: { category_id: category.id, name: "Pollo entero", price: 3500.00, available: true } }
    end

    it "creates a menu item as admin" do
      expect {
        post "/api/v1/menu_items", params: valid_params, headers: auth_headers(admin)
      }.to change(MenuItem, :count).by(1)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["name"]).to eq("Pollo entero")
    end

    it "returns error for missing name" do
      post "/api/v1/menu_items",
           params: { menu_item: { category_id: category.id, price: 1500.00 } },
           headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for non-admin" do
      post "/api/v1/menu_items", params: valid_params, headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      post "/api/v1/menu_items", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/menu_items/:id ────────────────────────────────────────

  describe "PATCH /api/v1/menu_items/:id" do
    let(:item) { create(:menu_item, category: category, name: "Medio pollo") }

    it "updates a menu item as admin" do
      patch "/api/v1/menu_items/#{item.id}",
            params: { menu_item: { name: "Cuarto de pollo", price: 1800.00 } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(item.reload.name).to eq("Cuarto de pollo")
    end

    it "updates availability" do
      patch "/api/v1/menu_items/#{item.id}",
            params: { menu_item: { available: false } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
      expect(item.reload.available).to be false
    end

    it "returns error for invalid price" do
      patch "/api/v1/menu_items/#{item.id}",
            params: { menu_item: { price: -100 } },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for non-admin" do
      patch "/api/v1/menu_items/#{item.id}",
            params: { menu_item: { name: "Hack" } },
            headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ─── DELETE /api/v1/menu_items/:id ───────────────────────────────────────

  describe "DELETE /api/v1/menu_items/:id" do
    let!(:item) { create(:menu_item, category: category) }

    it "deletes a menu item as admin" do
      expect {
        delete "/api/v1/menu_items/#{item.id}", headers: auth_headers(admin)
      }.to change(MenuItem, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "returns 403 for non-admin" do
      delete "/api/v1/menu_items/#{item.id}", headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      delete "/api/v1/menu_items/#{item.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
