require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { should have_many(:menu_items).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:category) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "default_scope" do
    it "orders by position ascending" do
      cat3 = create(:category, position: 3)
      cat1 = create(:category, position: 1)
      cat2 = create(:category, position: 2)
      expect(Category.all.map(&:id)).to eq([cat1.id, cat2.id, cat3.id])
    end
  end
end
