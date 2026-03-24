require "rails_helper"

RSpec.describe "Billing API", type: :request do
  let(:tenant)       { create(:tenant) }
  let(:admin)        { create(:user, :admin) }
  let(:customer)     { create(:user) }
  let(:subscription) { create(:subscription, tenant: tenant, started_at: 3.months.ago.to_date) }

  # Stubeamos el método privado para evitar que el TenantResolver middleware
  # intente hacer switch al schema del subdomain (que no existe en tests).
  def stub_subscription(sub)
    allow_any_instance_of(Api::V1::BillingController)
      .to receive(:current_tenant_subscription).and_return(sub)
    allow_any_instance_of(Api::V1::BillingController)
      .to receive(:fetch_delivered_sales_for_current_month).and_return(500_000)
  end

  describe "GET /api/v1/billing" do
    context "when tenant has an active subscription" do
      before { stub_subscription(subscription) }

      it "returns 200 for admin" do
        get "/api/v1/billing", headers: auth_headers(admin)
        expect(response).to have_http_status(:ok)
      end

      it "returns subscription details" do
        get "/api/v1/billing", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["subscription"]["id"]).to eq(subscription.id)
        expect(json["subscription"]["status"]).to eq("active")
        expect(json["subscription"]["current_billing_month"]).to be_a(Integer)
        expect(json["subscription"]["current_plan"]).to be_present
      end

      it "returns current_month estimation" do
        create(:exchange_rate, year: Date.today.year, month: Date.today.month, blue_rate: 1500.0)

        get "/api/v1/billing", headers: auth_headers(admin)
        json = JSON.parse(response.body)

        expect(json["current_month"]["plan"]).to be_present
        expect(json["current_month"]["usd_base"]).to be_a(Numeric)
        expect(json["current_month"]["base_ars"]).to be_a(Numeric)
        expect(json["current_month"]["estimated_total"]).to be_a(Numeric)
        expect(json["current_month"]["next_due_date"]).to be_present
      end

      it "returns 0 blue_rate when no exchange rate exists for current month" do
        get "/api/v1/billing", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["current_month"]["blue_rate"]).to eq(0)
      end

      it "returns billing history" do
        create(:billing_period, subscription: subscription)

        get "/api/v1/billing", headers: auth_headers(admin)
        json = JSON.parse(response.body)

        expect(json["history"]).to be_an(Array)
        expect(json["history"].first.keys).to include(
          "id", "year", "month", "plan", "base_ars", "total_ars", "status"
        )
      end

      it "limits history to 12 periods" do
        # 13 períodos con year/month únicos
        (1..13).each do |i|
          year  = 2024 + ((i - 1) / 12)
          month = ((i - 1) % 12) + 1
          create(:billing_period,
                 subscription: subscription,
                 year: year,
                 month: month,
                 billing_month_number: i)
        end

        get "/api/v1/billing", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["history"].size).to be <= 12
      end
    end

    context "when tenant has no active subscription" do
      before { stub_subscription(nil) }

      it "returns 404" do
        get "/api/v1/billing", headers: auth_headers(admin)
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message" do
        get "/api/v1/billing", headers: auth_headers(admin)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end

    context "authorization" do
      before { stub_subscription(subscription) }

      it "returns 403 for non-admin users" do
        get "/api/v1/billing", headers: auth_headers(customer)
        expect(response).to have_http_status(:forbidden)
      end

      it "returns 401 when unauthenticated" do
        get "/api/v1/billing"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
