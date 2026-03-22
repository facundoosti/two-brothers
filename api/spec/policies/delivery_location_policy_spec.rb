require "rails_helper"

RSpec.describe DeliveryLocationPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }
  let(:other)    { create(:user, role: :customer) }

  let(:order)      { create(:order, :delivery, user: customer) }
  let(:assignment) { create(:delivery_assignment, user: delivery, order: order) }

  permissions :create? do
    it { expect(subject).to permit(delivery, assignment) }
    it { expect(subject).not_to permit(admin, assignment) }
    it { expect(subject).not_to permit(customer, assignment) }
  end

  permissions :latest? do
    it "permite al admin" do
      expect(subject).to permit(admin, assignment)
    end

    it "permite al customer dueño de la orden" do
      expect(subject).to permit(customer, assignment)
    end

    it "deniega a un customer que no es dueño" do
      expect(subject).not_to permit(other, assignment)
    end

    it "deniega al repartidor" do
      expect(subject).not_to permit(delivery, assignment)
    end
  end
end
