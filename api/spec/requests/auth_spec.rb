require "rails_helper"

RSpec.describe "Auth API", type: :request do
  describe "POST /api/v1/auth/google" do
    let(:google_payload) do
      {
        "sub"     => "google-uid-auth-test",
        "email"   => "auth_user@example.com",
        "name"    => "Auth User",
        "picture" => "https://example.com/avatar.jpg"
      }
    end

    let(:mock_response) do
      instance_double(HTTParty::Response,
        success?:       true,
        parsed_response: google_payload
      )
    end

    before do
      allow(HTTParty).to receive(:get).and_return(mock_response)
    end

    context "with a valid Google token for an active user" do
      it "returns a token and user data" do
        post "/api/v1/auth/google", params: { access_token: "valid_token" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["token"]).to be_present
        expect(json["user"]["email"]).to eq("auth_user@example.com")
      end

      it "creates the user if not found" do
        expect {
          post "/api/v1/auth/google", params: { access_token: "valid_token" }
        }.to change(User, :count).by(1)
      end
    end

    context "with a valid token for a pending user" do
      before do
        create(:user, :pending, provider: "google", uid: "google-uid-auth-test",
               email: "auth_user@example.com")
      end

      it "returns 403 forbidden" do
        post "/api/v1/auth/google", params: { access_token: "valid_token" }
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq(I18n.t("errors.account_pending"))
      end
    end

    context "when Google token verification fails" do
      before do
        allow(mock_response).to receive(:success?).and_return(false)
      end

      it "returns 401 unauthorized" do
        post "/api/v1/auth/google", params: { access_token: "invalid_token" }
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq(I18n.t("errors.oauth_failed"))
      end
    end

    context "when HTTParty raises an exception" do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError, "network error")
      end

      it "returns 401 with oauth_failed error" do
        post "/api/v1/auth/google", params: { access_token: "any_token" }
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq(I18n.t("errors.oauth_failed"))
      end
    end

    context "when User.from_google raises an exception" do
      before do
        allow(User).to receive(:from_google).and_raise(StandardError, "db error")
      end

      it "returns 401 with oauth_failed error" do
        post "/api/v1/auth/google", params: { access_token: "valid_token" }
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq(I18n.t("errors.oauth_failed"))
      end
    end
  end
end
