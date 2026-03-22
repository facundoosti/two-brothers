require "rails_helper"

RSpec.describe Setting, type: :model do
  describe "validations" do
    subject { build(:setting) }

    it { should validate_presence_of(:key) }
    it { should validate_presence_of(:value) }
    it { should validate_uniqueness_of(:key) }
  end

  describe ".[]" do
    it "returns the value for an existing key" do
      Setting["store_name"] = "Two Brothers"
      expect(Setting["store_name"]).to eq("Two Brothers")
    end

    it "returns nil for a missing key" do
      expect(Setting["nonexistent_key"]).to be_nil
    end
  end

  describe ".[]=" do
    it "creates a new setting" do
      expect { Setting["new_key"] = "value" }.to change(Setting, :count).by(1)
      expect(Setting["new_key"]).to eq("value")
    end

    it "updates an existing setting" do
      Setting["store_name"] = "Old Name"
      Setting["store_name"] = "New Name"
      expect(Setting["store_name"]).to eq("New Name")
      expect(Setting.where(key: "store_name").count).to eq(1)
    end

    it "coerces value to string" do
      Setting["daily_chicken_stock"] = 100
      expect(Setting["daily_chicken_stock"]).to eq("100")
    end
  end
end
