require "rails_helper"

RSpec.describe BillingPeriod, type: :model do
  let(:tenant)       { create(:tenant) }
  let(:subscription) { create(:subscription, tenant: tenant, started_at: Date.new(2025, 12, 1)) }
  let(:year)         { 2026 }
  let(:month)        { 3 }

  before do
    # Stub Apartment to avoid schema switching in unit tests
    allow(Apartment::Tenant).to receive(:switch).and_yield
  end

  describe ".generate_for" do
    context "when exchange rate exists" do
      let!(:rate) { create(:exchange_rate, year: year, month: month, blue_rate: 1415.0) }

      it "calculates base + variable correctly for plan adopcion" do
        # subscription started 2025-12, so 2026/03 = month 4 → adopcion
        allow(Order).to receive_message_chain(:where, :where, :sum).and_return(1_000_000)

        bp = BillingPeriod.generate_for(subscription, year, month)

        expect(bp.plan).to eq("adopcion")
        expect(bp.usd_base).to eq(25.0)
        expect(bp.base_ars).to eq(25.0 * 1415.0)
        expect(bp.variable_pct).to eq(0.005)
        expect(bp.variable_ars).to eq(1_000_000 * 0.005)
        expect(bp.total_ars).to eq(bp.base_ars + bp.variable_ars)
      end

      it "sets variable_ars to 0 for plan penetracion" do
        sub_new = create(:subscription, tenant: create(:tenant), started_at: Date.new(2026, 3, 1))
        allow(Order).to receive_message_chain(:where, :where, :sum).and_return(500_000)

        bp = BillingPeriod.generate_for(sub_new, year, month)

        expect(bp.plan).to eq("penetracion")
        expect(bp.variable_pct).to eq(0.0)
        expect(bp.variable_ars).to eq(0.0)
        expect(bp.total_ars).to eq(bp.base_ars)
      end

      it "sets variable_pct to 0.003 and usd_base to 20 for plan puente" do
        sub_puente = create(:subscription, tenant: create(:tenant), started_at: Date.new(2026, 1, 1))
        allow(Order).to receive_message_chain(:where, :where, :sum).and_return(200_000)

        bp = BillingPeriod.generate_for(sub_puente, year, month)

        expect(bp.plan).to eq("puente")
        expect(bp.usd_base).to eq(20.0)
        expect(bp.variable_pct).to eq(0.003)
      end

      it "sets due_date to day 5 of the following month" do
        allow(Order).to receive_message_chain(:where, :where, :sum).and_return(0)
        bp = BillingPeriod.generate_for(subscription, year, month)
        expect(bp.due_date).to eq(Date.new(year, month, 1).next_month + 4)
      end

      it "sets status to pending" do
        allow(Order).to receive_message_chain(:where, :where, :sum).and_return(0)
        bp = BillingPeriod.generate_for(subscription, year, month)
        expect(bp.status).to eq("pending")
      end

      it "raises if a period already exists for the same subscription/month" do
        allow(Order).to receive_message_chain(:where, :where, :sum).and_return(0)
        BillingPeriod.generate_for(subscription, year, month)

        expect do
          BillingPeriod.generate_for(subscription, year, month)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context "when exchange rate does not exist" do
      it "raises an error" do
        expect do
          BillingPeriod.generate_for(subscription, year, month)
        end.to raise_error(RuntimeError, /sin cotización blue/i)
      end
    end
  end
end
