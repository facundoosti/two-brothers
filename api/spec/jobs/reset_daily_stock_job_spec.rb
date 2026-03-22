require "rails_helper"

RSpec.describe ResetDailyStockJob, type: :job do
  it "creates a DailyStock record for today if it does not exist" do
    expect { described_class.perform_now }.to change(DailyStock, :count).by(1)
    expect(DailyStock.find_by(date: Date.current)).to be_present
  end

  it "does not create a duplicate if the record already exists" do
    DailyStock.today
    expect { described_class.perform_now }.not_to change(DailyStock, :count)
  end

  it "initializes the new day with used: 0" do
    described_class.perform_now
    stock = DailyStock.find_by(date: Date.current)
    expect(stock.used).to eq(0)
  end
end
