require "rails_helper"

RSpec.describe CategoryPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }
  let(:category) { create(:category) }

  permissions :create?, :update?, :destroy? do
    it { expect(subject).to permit(admin, category) }
    it { expect(subject).not_to permit(customer, category) }
    it { expect(subject).not_to permit(delivery, category) }
  end
end
