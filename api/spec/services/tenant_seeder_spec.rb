require "rails_helper"

RSpec.describe TenantSeeder do
  describe ".call" do
    it "calls seed methods within the tenant schema" do
      allow(Apartment::Tenant).to receive(:switch).and_yield
      allow(described_class).to receive(:seed_settings)
      allow(described_class).to receive(:seed_categories)

      described_class.call("empresa1", name: "Empresa Uno")

      expect(described_class).to have_received(:seed_settings).with("Empresa Uno")
      expect(described_class).to have_received(:seed_categories)
    end
  end

  describe ".seed_settings" do
    it "creates the default settings" do
      Setting.delete_all
      described_class.seed_settings("Test Store")
      expect(Setting["store_name"]).to eq("Test Store")
      expect(Setting["open_days"]).to eq("4,5,6,0")
      expect(Setting["opening_time"]).to eq("20:00")
      expect(Setting["closing_time"]).to eq("00:00")
    end
  end

  describe ".seed_categories" do
    it "creates the default categories" do
      Category.delete_all
      described_class.seed_categories
      names = Category.pluck(:name)
      expect(names).to include("Principal", "Adicionales", "Bebidas")
    end

    it "is idempotent — does not duplicate categories" do
      described_class.seed_categories
      expect { described_class.seed_categories }.not_to change(Category, :count)
    end
  end
end
