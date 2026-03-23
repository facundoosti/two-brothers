require "rails_helper"

RSpec.describe StoreSchedule do
  let(:tz) { ActiveSupport::TimeZone["America/Argentina/Buenos_Aires"] }

  before do
    Setting.delete_all
  end

  describe ".open?" do
    context "with default settings (Thu-Sun, 20:00-00:00)" do
      it "returns true on Thursday at 20:30" do
        travel_to tz.local(2026, 3, 19, 20, 30, 0) do # Thursday
          expect(described_class.open?).to be true
        end
      end

      it "returns true on Friday at 22:00" do
        travel_to tz.local(2026, 3, 20, 22, 0, 0) do # Friday
          expect(described_class.open?).to be true
        end
      end

      it "returns true on Saturday at 21:00" do
        travel_to tz.local(2026, 3, 21, 21, 0, 0) do # Saturday
          expect(described_class.open?).to be true
        end
      end

      it "returns true on Sunday at 20:00" do
        travel_to tz.local(2026, 3, 22, 20, 0, 0) do # Sunday
          expect(described_class.open?).to be true
        end
      end

      it "returns false on Monday" do
        travel_to tz.local(2026, 3, 23, 21, 0, 0) do # Monday
          expect(described_class.open?).to be false
        end
      end

      it "returns false on Tuesday" do
        travel_to tz.local(2026, 3, 24, 21, 0, 0) do # Tuesday
          expect(described_class.open?).to be false
        end
      end

      it "returns false on Wednesday" do
        travel_to tz.local(2026, 3, 25, 21, 0, 0) do # Wednesday
          expect(described_class.open?).to be false
        end
      end

      it "returns false before opening time on Thursday" do
        travel_to tz.local(2026, 3, 19, 19, 59, 0) do
          expect(described_class.open?).to be false
        end
      end

      it "returns false after midnight (01:00 on next day)" do
        travel_to tz.local(2026, 3, 20, 1, 0, 0) do # Friday 01:00
          expect(described_class.open?).to be false
        end
      end

      it "returns true just before midnight (23:59) on Thursday" do
        travel_to tz.local(2026, 3, 19, 23, 59, 0) do # Thursday 23:59
          expect(described_class.open?).to be true
        end
      end

      it "returns false at midnight (00:00) Friday — store session closed" do
        travel_to tz.local(2026, 3, 20, 0, 0, 0) do # Friday 00:00 (start of Friday, before 20:00)
          expect(described_class.open?).to be false
        end
      end
    end

    context "with custom settings" do
      before do
        Setting["open_days"]    = "1,2,3"   # Mon, Tue, Wed
        Setting["opening_time"] = "10:00"
        Setting["closing_time"] = "18:00"
      end

      it "returns true on Monday at 12:00" do
        travel_to tz.local(2026, 3, 23, 12, 0, 0) do # Monday
          expect(described_class.open?).to be true
        end
      end

      it "returns false on Thursday (not in custom open_days)" do
        travel_to tz.local(2026, 3, 19, 21, 0, 0) do # Thursday
          expect(described_class.open?).to be false
        end
      end

      it "returns false before opening time" do
        travel_to tz.local(2026, 3, 23, 9, 59, 0) do # Monday 09:59
          expect(described_class.open?).to be false
        end
      end

      it "returns false after closing time" do
        travel_to tz.local(2026, 3, 23, 18, 1, 0) do # Monday 18:01
          expect(described_class.open?).to be false
        end
      end
    end
  end
end
