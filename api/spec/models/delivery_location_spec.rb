require "rails_helper"

RSpec.describe DeliveryLocation, type: :model do
  describe "associations" do
    it { should belong_to(:delivery_assignment) }
  end

  describe "validations" do
    subject { build(:delivery_location) }

    it { should validate_presence_of(:latitude) }
    it { should validate_presence_of(:longitude) }
    it { should validate_presence_of(:recorded_at) }
    it { should validate_numericality_of(:latitude) }
    it { should validate_numericality_of(:longitude) }
  end

  describe ".latest scope" do
    let(:assignment) { create(:delivery_assignment) }

    it "returns the most recently recorded location" do
      create(:delivery_location, delivery_assignment: assignment, recorded_at: 10.minutes.ago)
      newer = create(:delivery_location, delivery_assignment: assignment, recorded_at: 1.minute.ago)
      expect(assignment.delivery_locations.latest).to eq(newer)
    end
  end
end
