require 'rails_helper'

RSpec.describe DeliverySetting, type: :model do
  describe "validations" do
    it "frequencyが必須である" do
      setting = build(:delivery_setting, frequency: nil)

      expect(setting).not_to be_valid
      expect(setting.errors[:frequency]).to be_present
    end

    it "delivery_time_1が必須である" do
      setting = build(:delivery_setting, delivery_time_1: nil)

      expect(setting).not_to be_valid
      expect(setting.errors[:delivery_time_1]).to be_present
    end

    it "userが必須である" do
      setting = build(:delivery_setting, user: nil)

      expect(setting).not_to be_valid
      expect(setting.errors[:user]).to be_present
    end

    it "user_idは一意である" do
      user = create(:user)
      create(:delivery_setting, user: user)
      second_setting = build(:delivery_setting, user: user)

      expect(second_setting).not_to be_valid
      expect(second_setting.errors[:user_id]).to be_present
    end
  end

  describe "#delivery_times_must_differ" do
    context "delivery_time_2が未設定の場合" do
      it "バリデーションエラーにならない" do
        setting = build(:delivery_setting, delivery_time_1: Time.zone.parse("08:00"), delivery_time_2: nil)

        expect(setting).to be_valid
      end
    end

    context "delivery_time_1とdelivery_time_2が同じ時刻の場合" do
      let(:setting) do
        build(
          :delivery_setting,
          delivery_time_1: Time.zone.parse("08:00"),
          delivery_time_2: Time.zone.parse("08:00")
        )
      end

      it "delivery_time_2にバリデーションエラーが追加される" do
        setting.valid?

        expect(setting.errors[:delivery_time_2]).to include("は配信時間①と異なる時刻を設定してください")
      end

      it "保存できない" do
        expect(setting.save).to eq(false)
      end
    end

    context "delivery_time_1とdelivery_time_2が異なる時刻の場合" do
      it "バリデーションエラーにならない" do
        setting = build(
          :delivery_setting,
          delivery_time_1: Time.zone.parse("08:00"),
          delivery_time_2: Time.zone.parse("20:00")
        )

        expect(setting).to be_valid
      end
    end
  end
end
