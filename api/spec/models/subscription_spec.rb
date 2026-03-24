require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "validations" do
    subject { build(:subscription) }

    it { should belong_to(:tenant) }
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:status) }

    it "is invalid when started_at is in the future" do
      sub = build(:subscription, started_at: Date.tomorrow)
      expect(sub).not_to be_valid
      expect(sub.errors[:started_at]).to be_present
    end

    it "is valid when started_at is today" do
      sub = build(:subscription, started_at: Date.today)
      expect(sub).to be_valid
    end

    it "is valid when started_at is in the past" do
      sub = build(:subscription, started_at: 1.year.ago.to_date)
      expect(sub).to be_valid
    end
  end

  describe "uniqueness: at most one active/suspended per tenant" do
    let(:tenant) { create(:tenant) }

    it "allows a second subscription if the first is cancelled" do
      create(:subscription, tenant: tenant, status: :cancelled)
      new_sub = build(:subscription, tenant: tenant, status: :active)
      expect(new_sub).to be_valid
    end

    it "rejects a second active subscription for the same tenant" do
      create(:subscription, tenant: tenant, status: :active)
      new_sub = build(:subscription, tenant: tenant, status: :active)
      expect(new_sub).not_to be_valid
      expect(new_sub.errors[:tenant]).to be_present
    end

    it "rejects creating an active subscription when one is suspended" do
      create(:subscription, :suspended, tenant: tenant)
      new_sub = build(:subscription, tenant: tenant, status: :active)
      expect(new_sub).not_to be_valid
    end
  end

  describe "#current_billing_month" do
    it "returns 1 if started_at is in the current month" do
      sub = build(:subscription, started_at: Date.today.beginning_of_month)
      expect(sub.current_billing_month).to eq(1)
    end

    it "returns 2 if started_at was last month" do
      sub = build(:subscription, started_at: Date.today.prev_month.beginning_of_month)
      expect(sub.current_billing_month).to eq(2)
    end

    it "returns 4 if started_at was 3 months ago" do
      sub = build(:subscription, started_at: 3.months.ago.to_date)
      expect(sub.current_billing_month).to eq(4)
    end
  end

  describe "#current_plan" do
    it "returns :penetracion in months 1 and 2" do
      sub = build(:subscription, started_at: Date.today)
      expect(sub.current_plan).to eq(:penetracion)

      sub2 = build(:subscription, started_at: Date.today.prev_month)
      expect(sub2.current_plan).to eq(:penetracion)
    end

    it "returns :puente in month 3" do
      sub = build(:subscription, started_at: 2.months.ago.to_date)
      expect(sub.current_plan).to eq(:puente)
    end

    it "returns :adopcion in month 4 and higher" do
      sub4 = build(:subscription, started_at: 3.months.ago.to_date)
      expect(sub4.current_plan).to eq(:adopcion)

      sub10 = build(:subscription, started_at: 9.months.ago.to_date)
      expect(sub10.current_plan).to eq(:adopcion)
    end
  end

  describe "#billing_month_for" do
    it "calculates the billing month for a given year/month" do
      sub = build(:subscription, started_at: Date.new(2026, 1, 15))
      expect(sub.billing_month_for(2026, 1)).to eq(1)
      expect(sub.billing_month_for(2026, 2)).to eq(2)
      expect(sub.billing_month_for(2026, 3)).to eq(3)
      expect(sub.billing_month_for(2026, 4)).to eq(4)
    end
  end
end
