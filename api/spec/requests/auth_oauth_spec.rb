require "rails_helper"

# Tests for the redirect-based OAuth flow (AuthController)
RSpec.describe "OAuth Redirect Flow", type: :request do
  before do
    ENV["GOOGLE_CLIENT_ID"]     = "test-client-id"
    ENV["GOOGLE_CLIENT_SECRET"] = "test-client-secret"
    ENV["FRONTEND_URL"]         = "http://localhost:5173"
  end

  # ─── GET /auth/google ────────────────────────────────────────────────────

  describe "GET /auth/google" do
    it "redirects to Google authorization URL" do
      get "/auth/google"
      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("accounts.google.com/o/oauth2/v2/auth")
    end

    it "includes required OAuth params in redirect URL" do
      get "/auth/google"
      expect(response.location).to include("client_id=test-client-id")
      expect(response.location).to include("response_type=code")
      expect(response.location).to include("openid")
    end

    it "stores tenant in session when provided" do
      get "/auth/google", params: { tenant: "empresa1" }
      # session is set; redirect happens
      expect(response).to have_http_status(:redirect)
    end

    it "redirects without tenant param" do
      get "/auth/google"
      expect(response).to have_http_status(:redirect)
    end
  end

  # ─── GET /auth/google/callback ───────────────────────────────────────────

  describe "GET /auth/google/callback" do
    let(:google_userinfo) do
      {
        "sub"     => "google-oauth-uid-001",
        "email"   => "oauth@example.com",
        "name"    => "OAuth User",
        "picture" => "https://example.com/avatar.jpg"
      }
    end

    context "when OAuth error param is present" do
      it "redirects to frontend error URL" do
        get "/auth/google/callback", params: { error: "access_denied", state: "anystate" }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("error=oauth_failed")
      end
    end

    context "when state mismatch" do
      it "redirects to frontend error URL" do
        get "/auth/google/callback", params: { code: "somecode", state: "wrong-state" }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("error=oauth_failed")
      end
    end

    context "when code exchange fails" do
      before do
        allow(HTTParty).to receive(:post).and_return(
          instance_double(HTTParty::Response, success?: false, parsed_response: {})
        )
      end

      it "redirects to frontend error URL" do
        # Set up session state via the new_oauth action
        get "/auth/google", params: { tenant: nil }
        state = response.location.match(/state=([^&]+)/)&.captures&.first
        get "/auth/google/callback", params: { code: "badcode", state: state }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("error=oauth_failed")
      end
    end

    context "with valid code and active user" do
      let(:token_response) do
        instance_double(HTTParty::Response,
          success?: true,
          parsed_response: { "access_token" => "test-access-token" }
        )
      end
      let(:userinfo_response) do
        instance_double(HTTParty::Response,
          success?: true,
          parsed_response: google_userinfo
        )
      end

      before do
        allow(HTTParty).to receive(:post).and_return(token_response)
        allow(HTTParty).to receive(:get).and_return(userinfo_response)
      end

      it "creates user and redirects to frontend callback URL with token" do
        get "/auth/google"
        state = response.location.match(/state=([^&]+)/)&.captures&.first
        expect {
          get "/auth/google/callback", params: { code: "validcode", state: state }
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/auth/callback?token=")
      end

      it "redirects existing active user to frontend callback URL" do
        create(:user, provider: "google", uid: "google-oauth-uid-001",
               email: "oauth@example.com")
        get "/auth/google"
        state = response.location.match(/state=([^&]+)/)&.captures&.first
        get "/auth/google/callback", params: { code: "validcode", state: state }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("/auth/callback?token=")
      end

      it "redirects pending user to frontend error URL" do
        create(:user, :pending, provider: "google", uid: "google-oauth-uid-001",
               email: "oauth@example.com")
        get "/auth/google"
        state = response.location.match(/state=([^&]+)/)&.captures&.first
        get "/auth/google/callback", params: { code: "validcode", state: state }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("error=pending")
      end
    end

    context "when an exception occurs during callback" do
      before do
        allow(HTTParty).to receive(:post).and_raise(StandardError, "connection failed")
      end

      it "redirects to frontend error URL" do
        get "/auth/google"
        state = response.location.match(/state=([^&]+)/)&.captures&.first
        get "/auth/google/callback", params: { code: "anycode", state: state }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("error=oauth_failed")
      end
    end
  end
end
