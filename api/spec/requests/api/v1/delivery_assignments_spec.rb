require "rails_helper"

RSpec.describe "Delivery Assignments API", type: :request do
  let(:admin)         { create(:user, :admin) }
  let(:customer)      { create(:user) }
  let(:delivery_user) { create(:user, :delivery) }

  # ─── GET /api/v1/delivery_assignments ────────────────────────────────────

  describe "GET /api/v1/delivery_assignments" do
    let(:order) { create(:order, :delivering) }
    let!(:assignment) { create(:delivery_assignment, user: delivery_user, order: order) }
    let!(:assignment2) { create(:delivery_assignment, user: delivery_user, order: create(:order, :delivering)) }

    context "as admin" do
      it "returns all assignments" do
        get "/api/v1/delivery_assignments", headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to be >= 1
        expect(json["pagy"]).to be_present
      end
    end

    context "as delivery user" do
      let!(:other_assignment) { create(:delivery_assignment) }

      it "returns only own assignments" do
        get "/api/v1/delivery_assignments", headers: auth_headers(delivery_user)
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        ids = json["data"].map { |a| a["id"] }
        expect(ids).to include(assignment.id)
        expect(ids).not_to include(other_assignment.id)
      end
    end

    context "as customer" do
      it "returns 403" do
        get "/api/v1/delivery_assignments", headers: auth_headers(customer)
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "returns 401 when unauthenticated" do
      get "/api/v1/delivery_assignments"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── POST /api/v1/delivery_assignments ───────────────────────────────────

  describe "POST /api/v1/delivery_assignments" do
    let(:order) { create(:order, :delivering, :with_item) }

    it "creates an assignment as admin and returns order items" do
      expect {
        post "/api/v1/delivery_assignments",
             params: { order_id: order.id, user_id: delivery_user.id },
             headers: auth_headers(admin)
      }.to change(DeliveryAssignment, :count).by(1)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["order"]).to be_present
      expect(json["order"]["order_items"]).to be_an(Array)
    end

    it "returns error when user is not a delivery user" do
      post "/api/v1/delivery_assignments",
           params: { order_id: order.id, user_id: customer.id },
           headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for non-admin" do
      post "/api/v1/delivery_assignments",
           params: { order_id: order.id, user_id: delivery_user.id },
           headers: auth_headers(customer)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      post "/api/v1/delivery_assignments",
           params: { order_id: order.id, user_id: delivery_user.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── PATCH /api/v1/delivery_assignments/:id/status ───────────────────────

  describe "PATCH /api/v1/delivery_assignments/:id/status" do
    # Order must be in :ready state so service can call order.start_delivering!
    let(:order)      { create(:order, :ready) }
    let(:assignment) { create(:delivery_assignment, user: delivery_user, order: order) }

    it "transitions to in_transit as delivery user" do
      patch "/api/v1/delivery_assignments/#{assignment.id}/status",
            params: { status: "in_transit" },
            headers: auth_headers(delivery_user)
      expect(response).to have_http_status(:ok)
      expect(assignment.reload.status).to eq("in_transit")
    end

    it "transitions to delivered as delivery user" do
      assignment.update!(status: :in_transit, departed_at: Time.current)
      order.update!(status: :delivering)
      patch "/api/v1/delivery_assignments/#{assignment.id}/status",
            params: { status: "delivered" },
            headers: auth_headers(delivery_user)
      expect(response).to have_http_status(:ok)
      expect(assignment.reload.status).to eq("delivered")
    end

    it "returns error for invalid transition" do
      patch "/api/v1/delivery_assignments/#{assignment.id}/status",
            params: { status: "delivered" },
            headers: auth_headers(delivery_user)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 for non-delivery user" do
      patch "/api/v1/delivery_assignments/#{assignment.id}/status",
            params: { status: "in_transit" },
            headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      patch "/api/v1/delivery_assignments/#{assignment.id}/status",
            params: { status: "in_transit" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
