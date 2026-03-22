require "rails_helper"

RSpec.describe DailyStock, type: :model do
  describe "validations" do
    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:total) }
    it { should validate_presence_of(:used) }
    it { should validate_numericality_of(:total).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:used).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_uniqueness_of(:date) }
  end

  describe ".today" do
    context "when no record exists for today" do
      it "creates a new record with default total of 100" do
        expect { DailyStock.today }.to change(DailyStock, :count).by(1)
        expect(DailyStock.today.total).to eq(100)
      end

      it "sets used to 0" do
        expect(DailyStock.today.used).to eq(0)
      end

      context "with a custom daily_chicken_stock setting" do
        before { Setting["daily_chicken_stock"] = "50" }

        it "uses the configured total" do
          expect(DailyStock.today.total).to eq(50)
        end
      end
    end

    context "when a record already exists for today" do
      let!(:stock) { create(:daily_stock, date: Date.current, total: 80, used: 20) }

      it "returns the existing record without creating a new one" do
        expect { DailyStock.today }.not_to change(DailyStock, :count)
        expect(DailyStock.today.id).to eq(stock.id)
      end
    end
  end

  describe "#available" do
    it "returns total minus used" do
      stock = build(:daily_stock, total: 100, used: 30)
      expect(stock.available).to eq(70)
    end
  end

  describe "#available?" do
    let(:stock) { build(:daily_stock, total: 10, used: 8) }

    it "returns true when enough stock is available" do
      expect(stock.available?(2)).to be true
    end

    it "returns false when not enough stock" do
      expect(stock.available?(3)).to be false
    end

    it "defaults quantity to 1" do
      expect(stock.available?).to be true
    end
  end
end
