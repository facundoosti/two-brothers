require "rails_helper"

RSpec.describe "Delivery Locations API", type: :request do
  let(:admin)         { create(:user, :admin) }
  let(:customer)      { create(:user) }
  let(:delivery_user) { create(:user, :delivery) }
  let(:order)         { create(:order, :delivering, user: customer) }
  let(:assignment)    { create(:delivery_assignment, user: delivery_user, order: order) }

  # ─── POST /api/v1/delivery_locations ─────────────────────────────────────

  describe "POST /api/v1/delivery_locations" do
    let(:valid_params) do
      {
        delivery_assignment_id: assignment.id,
        latitude:    -34.6037,
        longitude:   -58.3816,
        recorded_at: Time.current.iso8601
      }
    end

    it "creates a location as delivery user" do
      expect {
        post "/api/v1/delivery_locations", params: valid_params, headers: auth_headers(delivery_user)
      }.to change(DeliveryLocation, :count).by(1)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["latitude"].to_f).to be_within(0.001).of(-34.6037)
      expect(json["longitude"].to_f).to be_within(0.001).of(-58.3816)
    end

    it "defaults recorded_at to now when not provided" do
      params_without_time = valid_params.except(:recorded_at)
      post "/api/v1/delivery_locations", params: params_without_time, headers: auth_headers(delivery_user)
      expect(response).to have_http_status(:created)
    end

    it "returns 403 for non-delivery user" do
      post "/api/v1/delivery_locations", params: valid_params, headers: auth_headers(admin)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 when unauthenticated" do
      post "/api/v1/delivery_locations", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ─── GET /api/v1/delivery_assignments/:id/latest_location ─────────────────

  describe "GET /api/v1/delivery_assignments/:id/latest_location" do
    context "when a location exists" do
      before do
        create(:delivery_location, delivery_assignment: assignment,
               latitude: -34.60, longitude: -58.38, recorded_at: 2.minutes.ago)
        create(:delivery_location, delivery_assignment: assignment,
               latitude: -34.61, longitude: -58.39, recorded_at: 1.minute.ago)
      end

      it "returns the latest location for admin" do
        get "/api/v1/delivery_assignments/#{assignment.id}/latest_location",
            headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["latitude"].to_f).to be_within(0.001).of(-34.61)
        expect(json["longitude"].to_f).to be_within(0.001).of(-58.39)
      end

      it "returns the latest location for the order customer" do
        get "/api/v1/delivery_assignments/#{assignment.id}/latest_location",
            headers: auth_headers(customer)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when no location exists" do
      it "returns 404" do
        get "/api/v1/delivery_assignments/#{assignment.id}/latest_location",
            headers: auth_headers(admin)
        expect(response).to have_http_status(:not_found)
      end
    end

    it "returns 401 when unauthenticated" do
      get "/api/v1/delivery_assignments/#{assignment.id}/latest_location"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
