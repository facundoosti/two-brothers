require "rails_helper"

RSpec.describe DashboardPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }

  permissions :show? do
    it { expect(subject).to permit(admin, :dashboard) }
    it { expect(subject).not_to permit(customer, :dashboard) }
    it { expect(subject).not_to permit(delivery, :dashboard) }
  end
end
