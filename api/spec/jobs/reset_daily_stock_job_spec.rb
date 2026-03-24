require "rails_helper"

RSpec.describe ResetDailyStockJob, type: :job do
  let!(:item_a) { create(:menu_item, available: true,  daily_stock: 50) }
  let!(:item_b) { create(:menu_item, available: true,  daily_stock: 30) }
  let!(:item_c) { create(:menu_item, available: false, daily_stock: 20) } # unavailable — skipped
  let!(:item_d) { create(:menu_item, :no_stock) }                          # nil stock — skipped

  it "creates DailyStock records for all active items with positive daily_stock" do
    expect { described_class.perform_now }.to change(DailyStock, :count).by(2)
  end

  it "seeds total from each item's daily_stock" do
    described_class.perform_now
    expect(DailyStock.find_by(menu_item: item_a, date: Date.current).total).to eq(50)
    expect(DailyStock.find_by(menu_item: item_b, date: Date.current).total).to eq(30)
  end

  it "initializes used to 0 for new records" do
    described_class.perform_now
    DailyStock.where(menu_item: [ item_a, item_b ], date: Date.current).each do |s|
      expect(s.used).to eq(0)
    end
  end

  it "skips unavailable items" do
    described_class.perform_now
    expect(DailyStock.find_by(menu_item: item_c, date: Date.current)).to be_nil
  end

  it "skips items with nil daily_stock" do
    described_class.perform_now
    expect(DailyStock.find_by(menu_item: item_d, date: Date.current)).to be_nil
  end

  it "does not create duplicate records if already exist" do
    described_class.perform_now
    expect { described_class.perform_now }.not_to change(DailyStock, :count)
  end
end
