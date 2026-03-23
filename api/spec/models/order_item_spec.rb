require "rails_helper"

RSpec.describe OrderItem, type: :model do
  describe "associations" do
    it { should belong_to(:order) }
    it { should belong_to(:menu_item) }
  end

  describe "validations" do
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
    it { should validate_presence_of(:unit_price) }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
  end

  describe "factory" do
    it "creates a valid order item" do
      item = build(:order_item)
      expect(item).to be_valid
    end

    it "is invalid without quantity" do
      item = build(:order_item, quantity: nil)
      expect(item).not_to be_valid
    end

    it "is invalid with quantity 0" do
      item = build(:order_item, quantity: 0)
      expect(item).not_to be_valid
    end

    it "is invalid with negative unit_price" do
      item = build(:order_item, unit_price: -1)
      expect(item).not_to be_valid
    end

    it "is valid with unit_price of 0" do
      item = build(:order_item, unit_price: 0)
      expect(item).to be_valid
    end
  end
end
