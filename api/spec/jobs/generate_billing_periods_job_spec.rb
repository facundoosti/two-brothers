require "rails_helper"

RSpec.describe GenerateBillingPeriodsJob, type: :job do
  let(:last_month) { Date.today.prev_month }
  let(:year)       { last_month.year }
  let(:month)      { last_month.month }

  before do
    allow(Apartment::Tenant).to receive(:switch).and_yield
    allow(Order).to receive_message_chain(:where, :where, :sum).and_return(0)
  end

  describe "#perform" do
    context "when exchange rate exists for last month" do
      let!(:rate) { create(:exchange_rate, year: year, month: month) }

      it "generates one billing period per active subscription" do
        create(:subscription, started_at: 2.months.ago.to_date)
        create(:subscription, started_at: 3.months.ago.to_date)

        expect { described_class.perform_now }.to change(BillingPeriod, :count).by(2)
      end

      it "ignores suspended subscriptions" do
        create(:subscription, started_at: 2.months.ago.to_date)
        create(:subscription, :suspended, started_at: 2.months.ago.to_date)

        expect { described_class.perform_now }.to change(BillingPeriod, :count).by(1)
      end

      it "ignores cancelled subscriptions" do
        create(:subscription, :cancelled, started_at: 2.months.ago.to_date)
        expect { described_class.perform_now }.not_to change(BillingPeriod, :count)
      end
    end

    context "when no exchange rate is registered for last month" do
      it "aborts and logs an error without generating periods" do
        create(:subscription, started_at: 2.months.ago.to_date)

        expect(Rails.logger).to receive(:error).with(/sin cotización blue/i)
        expect { described_class.perform_now }.not_to change(BillingPeriod, :count)
      end
    end
  end
end
