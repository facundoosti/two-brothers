require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }

  permissions :me? do
    it { expect(subject).to permit(admin, admin) }
    it { expect(subject).to permit(customer, customer) }
    it { expect(subject).to permit(delivery, delivery) }
  end

  permissions :index?, :update? do
    it { expect(subject).to permit(admin, customer) }
    it { expect(subject).not_to permit(customer, customer) }
    it { expect(subject).not_to permit(delivery, delivery) }
  end
end
