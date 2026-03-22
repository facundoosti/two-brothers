require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_presence_of(:uid) }
    it { should validate_presence_of(:provider) }
    it { should validate_presence_of(:role) }
    it { should validate_presence_of(:status) }
  end

  describe "associations" do
    it { should have_many(:orders).dependent(:destroy) }
    it { should have_many(:delivery_assignments).dependent(:destroy) }
  end

  describe "enums" do
    it { should define_enum_for(:role).with_values(customer: 0, delivery: 1, admin: 2) }
    it { should define_enum_for(:status).with_values(pending: 0, active: 1) }
  end

  describe "api_token" do
    it "is generated before create" do
      user = build(:user)
      expect(user.api_token).to be_nil
      user.save!
      expect(user.api_token).to be_present
    end

    it "is unique per user" do
      user1 = create(:user)
      user2 = create(:user)
      expect(user1.api_token).not_to eq(user2.api_token)
    end
  end

  describe ".from_google" do
    let(:payload) do
      {
        "sub"     => "google-123",
        "email"   => "jane@example.com",
        "name"    => "Jane Doe",
        "picture" => "https://example.com/avatar.jpg"
      }
    end

    it "creates a new user when not found" do
      expect { User.from_google(payload) }.to change(User, :count).by(1)
    end

    it "assigns customer role by default" do
      user = User.from_google(payload)
      expect(user).to be_customer
    end

    it "assigns active status by default" do
      user = User.from_google(payload)
      expect(user).to be_active
    end

    it "finds an existing user by provider + uid" do
      existing = create(:user, provider: "google", uid: "google-123", email: "old@example.com")
      user = User.from_google(payload)
      expect(user.id).to eq(existing.id)
      expect(user.email).to eq("jane@example.com")
    end

    it "does not change role on subsequent logins" do
      create(:user, :admin, provider: "google", uid: "google-123", email: "admin@example.com")
      user = User.from_google(payload)
      expect(user).to be_admin
    end
  end

  describe "#regenerate_api_token!" do
    it "updates the api_token" do
      user = create(:user)
      old_token = user.api_token
      user.regenerate_api_token!
      expect(user.reload.api_token).not_to eq(old_token)
    end
  end
end
