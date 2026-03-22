require "rails_helper"

RSpec.describe DeliveryAssignmentPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }
  let(:order)    { create(:order, :delivery) }
  let(:assignment) { create(:delivery_assignment, user: delivery, order: order) }

  permissions :index? do
    it { expect(subject).to permit(admin, assignment) }
    it { expect(subject).to permit(delivery, assignment) }
    it { expect(subject).not_to permit(customer, assignment) }
  end

  permissions :create? do
    it { expect(subject).to permit(admin, assignment) }
    it { expect(subject).not_to permit(delivery, assignment) }
    it { expect(subject).not_to permit(customer, assignment) }
  end

  permissions :update_status? do
    it "permite al repartidor dueño del reparto" do
      expect(subject).to permit(delivery, assignment)
    end

    it "deniega a otro repartidor" do
      other_delivery = create(:user, role: :delivery)
      expect(subject).not_to permit(other_delivery, assignment)
    end

    it { expect(subject).not_to permit(admin, assignment) }
    it { expect(subject).not_to permit(customer, assignment) }
  end

  describe DeliveryAssignmentPolicy::Scope do
    subject { described_class.new(user, DeliveryAssignment.all).resolve }

    let(:other_delivery) { create(:user, role: :delivery) }
    let(:other_assignment) { create(:delivery_assignment, user: other_delivery, order: create(:order, :delivery)) }

    before { assignment; other_assignment }

    context "admin" do
      let(:user) { admin }
      it { expect(subject.count).to eq(DeliveryAssignment.count) }
    end

    context "delivery" do
      let(:user) { delivery }
      it { expect(subject).to include(assignment) }
      it { expect(subject).not_to include(other_assignment) }
    end

    context "customer" do
      let(:user) { customer }
      it { expect(subject).to be_empty }
    end
  end
end
