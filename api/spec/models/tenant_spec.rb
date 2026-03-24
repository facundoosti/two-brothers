require "rails_helper"

RSpec.describe Tenant, type: :model do
  describe "validations" do
    subject { create(:tenant) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain) }

    it "accepts valid subdomain with lowercase letters" do
      tenant = build(:tenant, subdomain: "mi-empresa")
      expect(tenant).to be_valid
    end

    it "accepts valid subdomain with numbers" do
      tenant = build(:tenant, subdomain: "empresa123")
      expect(tenant).to be_valid
    end

    it "rejects subdomain with uppercase letters" do
      tenant = build(:tenant, subdomain: "MiEmpresa")
      expect(tenant).not_to be_valid
    end

    it "rejects subdomain with spaces" do
      tenant = build(:tenant, subdomain: "mi empresa")
      expect(tenant).not_to be_valid
    end

    it "rejects subdomain with special characters" do
      tenant = build(:tenant, subdomain: "mi_empresa")
      expect(tenant).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:active_tenant)   { create(:tenant, active: true) }
    let!(:inactive_tenant) { create(:tenant, active: false) }

    describe ".active" do
      it "returns only active tenants" do
        expect(Tenant.active).to include(active_tenant)
        expect(Tenant.active).not_to include(inactive_tenant)
      end
    end
  end
end
