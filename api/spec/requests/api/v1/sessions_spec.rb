require "rails_helper"

RSpec.describe "Sessions API", type: :request do
  let(:user) { create(:user) }

  describe "DELETE /api/v1/session" do
    it "returns 204 and regenerates the token" do
      old_token = user.api_token
      delete "/api/v1/session", headers: auth_headers(user)
      expect(response).to have_http_status(:no_content)
      expect(user.reload.api_token).not_to eq(old_token)
    end

    it "invalidates the old token" do
      old_token = user.api_token
      delete "/api/v1/session", headers: auth_headers(user)
      get "/api/v1/me", headers: { "Authorization" => "Bearer #{old_token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when unauthenticated" do
      delete "/api/v1/session"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
