require "rails_helper"

RSpec.describe OrderPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }
  let(:order)    { create(:order, user: customer) }
  let(:other)    { create(:user, role: :customer) }

  permissions :index? do
    it { expect(subject).to permit(admin, Order) }
    it { expect(subject).to permit(customer, Order) }
    it { expect(subject).not_to permit(delivery, Order) }
  end

  permissions :show? do
    it { expect(subject).to permit(admin, order) }
    it { expect(subject).to permit(customer, order) }
    it { expect(subject).not_to permit(other, order) }
    it { expect(subject).not_to permit(delivery, order) }
  end

  permissions :create? do
    it { expect(subject).to permit(admin, order) }
    it { expect(subject).to permit(customer, order) }
    it { expect(subject).not_to permit(delivery, order) }
  end

  permissions :confirm_payment?, :update_status?, :cancel? do
    it { expect(subject).to permit(admin, order) }
    it { expect(subject).not_to permit(customer, order) }
    it { expect(subject).not_to permit(delivery, order) }
  end

  describe OrderPolicy::Scope do
    subject { described_class.new(user, Order.all).resolve }

    context "admin" do
      let(:user) { admin }
      before { create_list(:order, 2) }

      it "retorna todas las órdenes" do
        expect(subject.count).to eq(Order.count)
      end
    end

    context "customer" do
      let(:user) { customer }
      before { create(:order, user: other) }

      it "retorna solo las órdenes propias" do
        expect(subject).to include(order)
        expect(subject).not_to include(Order.where(user: other).first)
      end
    end

    context "delivery" do
      let(:user) { delivery }

      it "retorna ninguna orden" do
        expect(subject).to be_empty
      end
    end
  end
end
