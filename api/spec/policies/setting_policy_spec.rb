require "rails_helper"

RSpec.describe SettingPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }

  permissions :show?, :update? do
    it { expect(subject).to permit(admin, :setting) }
    it { expect(subject).not_to permit(customer, :setting) }
    it { expect(subject).not_to permit(delivery, :setting) }
  end
end
