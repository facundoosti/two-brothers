require "rails_helper"

RSpec.describe MarkOverdueBillingPeriodsJob, type: :job do
  describe "#perform" do
    let!(:subscription) { create(:subscription) }

    it "marks pending periods whose due_date has passed as overdue" do
      overdue_bp = create(:billing_period,
                          subscription: subscription,
                          status: "pending",
                          due_date: Date.today - 2)

      # Verifica que el WHERE encuentra el registro antes del update
      expect(
        BillingPeriod.where(status: :pending).where("due_date < ?", Date.today).count
      ).to eq(1), "El registro no es encontrado por el WHERE — revisar schema/enum"

      described_class.perform_now

      expect(overdue_bp.reload).to be_overdue
    end

    it "does not touch pending periods whose due_date is today or in the future" do
      future_bp = create(:billing_period, subscription: subscription,
                          status: "pending",
                          due_date: Date.today)

      described_class.perform_now

      expect(future_bp.reload.status).to eq("pending")
    end

    it "does not touch already paid periods" do
      paid_bp = create(:billing_period, :paid,
                       subscription: subscription,
                       due_date: 1.day.ago.to_date)

      described_class.perform_now

      expect(paid_bp.reload.status).to eq("paid")
    end

    it "does not touch already overdue periods" do
      already_overdue = create(:billing_period, :overdue, subscription: subscription)

      expect { described_class.perform_now }
        .not_to change { already_overdue.reload.status }
    end
  end
end
