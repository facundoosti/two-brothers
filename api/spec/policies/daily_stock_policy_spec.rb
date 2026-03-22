require "rails_helper"

RSpec.describe DailyStockPolicy, type: :policy do
  subject { described_class }

  let(:admin)    { create(:user, role: :admin) }
  let(:customer) { create(:user, role: :customer) }
  let(:delivery) { create(:user, role: :delivery) }

  permissions :show?, :update? do
    it { expect(subject).to permit(admin, :daily_stock) }
    it { expect(subject).not_to permit(customer, :daily_stock) }
    it { expect(subject).not_to permit(delivery, :daily_stock) }
  end
end
