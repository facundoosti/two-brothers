require "rails_helper"

RSpec.describe DailyStock, type: :model do
  let(:menu_item) { create(:menu_item) }

  describe "validations" do
    # Provide a persisted subject with all required fields for shoulda-matchers
    subject { create(:daily_stock, menu_item: menu_item) }

    it { should validate_presence_of(:date) }
    it { should validate_presence_of(:total) }
    it { should validate_presence_of(:used) }
    it { should validate_numericality_of(:total).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_numericality_of(:used).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_uniqueness_of(:date).scoped_to(:menu_item_id) }
    it { should belong_to(:menu_item) }
  end

  describe ".for_item_today" do
    context "when no record exists for the item today" do
      it "creates a new record" do
        expect { DailyStock.for_item_today(menu_item) }.to change(DailyStock, :count).by(1)
      end

      it "seeds total from menu_item.daily_stock" do
        menu_item.update!(daily_stock: 75)
        stock = DailyStock.for_item_today(menu_item)
        expect(stock.total).to eq(75)
      end

      it "sets used to 0" do
        expect(DailyStock.for_item_today(menu_item).used).to eq(0)
      end
    end

    context "when a record already exists for the item today" do
      let!(:stock) { create(:daily_stock, menu_item: menu_item, date: Date.current, total: 80, used: 20) }

      it "returns the existing record without creating a new one" do
        expect { DailyStock.for_item_today(menu_item) }.not_to change(DailyStock, :count)
        expect(DailyStock.for_item_today(menu_item).id).to eq(stock.id)
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
