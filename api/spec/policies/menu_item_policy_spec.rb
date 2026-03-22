require "rails_helper"

RSpec.describe MenuItemPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }
  let(:item)     { create(:menu_item) }

  permissions :create?, :update?, :destroy? do
    it { expect(subject).to permit(admin, item) }
    it { expect(subject).not_to permit(customer, item) }
    it { expect(subject).not_to permit(delivery, item) }
  end
end
