require "rails_helper"

RSpec.describe DeliveryTimeCalculator do
  # テスト全体で共通して使う「配信設定」のダミーオブジェクトを作るヘルパー
  # build_stubbed は DB に保存しない軽量なテスト用インスタンスを作る
  let(:time_9am)  { Time.zone.parse("2000-01-01 09:00") }
  let(:time_9pm)  { Time.zone.parse("2000-01-01 21:00") }

  # 配信設定のダミーを作るヘルパーメソッド
  def build_setting(delivery_time_1:, delivery_time_2: nil, frequency: "daily")
    instance_double(
      "DeliverySetting",
      delivery_time_1: delivery_time_1,
      delivery_time_2: delivery_time_2,
      frequency:       frequency
    )
  end

  # -------------------------------------------------------
  # describe: テスト対象のメソッドやまとまりごとにグループ化する
  # -------------------------------------------------------
  describe ".call" do
    it "next_delivery_time の結果を返す" do
      setting = build_setting(delivery_time_1: time_9am, frequency: "daily")

      # 現在時刻を 08:00 に固定して「9時が未来」になるようにする
      travel_to Time.zone.parse("2025-06-08 08:00") do
        expect(described_class.call(setting)).to eq Time.zone.local(2025, 6, 8, 9, 0)
      end
    end
  end

  # -------------------------------------------------------
  # describe "#next_delivery_time" でメインメソッドをテスト
  # -------------------------------------------------------
  describe "#next_delivery_time" do
    # ===== 今日中に配信できるケース =====
    context "今日の配信時刻がまだ未来のとき" do
      it "delivery_time_1 が未来なら delivery_time_1 の時刻を返す" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "daily")

        travel_to Time.zone.parse("2025-06-08 08:00") do
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 8, 9, 0)
        end
      end

      it "delivery_time_1 が過去・delivery_time_2 が未来なら delivery_time_2 の時刻を返す" do
        setting = build_setting(delivery_time_1: time_9am, delivery_time_2: time_9pm, frequency: "daily")

        # 9時はすでに過ぎた状態（10時）
        travel_to Time.zone.parse("2025-06-08 10:00") do
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 8, 21, 0)
        end
      end

      it "delivery_time_1 と delivery_time_2 が両方未来なら早い方（delivery_time_1）を返す" do
        setting = build_setting(delivery_time_1: time_9am, delivery_time_2: time_9pm, frequency: "daily")

        travel_to Time.zone.parse("2025-06-08 08:00") do
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 8, 9, 0)
        end
      end
    end

    # ===== 今日はもう配信できない → 翌日以降を探すケース =====
    context "今日の配信時刻がすべて過去のとき" do
      it "daily 設定なら翌日の delivery_time_1 を返す" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "daily")

        # 22時 = delivery_time_1（9時）は今日もう過ぎた
        travel_to Time.zone.parse("2025-06-08 22:00") do
          result = described_class.call(setting)
          # 翌日（6/9）の 9:00 が返るはず
          expect(result).to eq Time.zone.local(2025, 6, 9, 9, 0)
        end
      end

      it "weekday 設定で翌日が土曜なら月曜の delivery_time_1 を返す" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "weekday")

        # 2025-06-06（金）の夜 → 翌日は土曜
        travel_to Time.zone.parse("2025-06-06 22:00") do
          result = described_class.call(setting)
          # 土・日を飛ばして月曜（6/9）の 9:00 が返るはず
          expect(result).to eq Time.zone.local(2025, 6, 9, 9, 0)
        end
      end

      it "weekend 設定で翌日が平日なら次の土曜の delivery_time_1 を返す" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "weekend")

        # 2025-06-08（日）の夜 → 翌日は月曜（平日）
        travel_to Time.zone.parse("2025-06-08 22:00") do
          result = described_class.call(setting)
          # 次の土曜（6/14）の 9:00 が返るはず
          expect(result).to eq Time.zone.local(2025, 6, 14, 9, 0)
        end
      end
    end

    # ===== delivery_time_2 が nil のケース =====
    context "delivery_time_2 が nil（未設定）のとき" do
      it "エラーにならず delivery_time_1 だけで判定する" do
        setting = build_setting(delivery_time_1: time_9am, delivery_time_2: nil, frequency: "daily")

        travel_to Time.zone.parse("2025-06-08 08:00") do
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 8, 9, 0)
        end
      end
    end
  end

  # -------------------------------------------------------
  # private メソッドの delivery_day? を間接的に検証する
  # ※ private なので外から直接呼ばず、next_delivery_time 経由でテスト
  # -------------------------------------------------------
  describe "配信曜日の判定（delivery_day? の間接テスト）" do
    context "daily のとき" do
      it "月曜でも配信する" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "daily")
        travel_to Time.zone.parse("2025-06-09 22:00") do # 月曜の夜
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 10, 9, 0) # 翌日（火）9時
        end
      end

      it "土曜でも配信する" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "daily")
        travel_to Time.zone.parse("2025-06-07 22:00") do # 土曜の夜
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 8, 9, 0) # 翌日（日）9時
        end
      end
    end

    context "weekday のとき" do
      it "月〜金は配信対象になる" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "weekday")
        travel_to Time.zone.parse("2025-06-08 22:00") do # 日曜の夜
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 9, 9, 0) # 翌月曜
        end
      end

      it "土・日は配信しない（次の平日を探す）" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "weekday")
        travel_to Time.zone.parse("2025-06-06 22:00") do # 金曜の夜
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 9, 9, 0) # 土・日を飛ばして月曜
        end
      end
    end

    context "weekend のとき" do
      it "土・日は配信対象になる" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "weekend")
        travel_to Time.zone.parse("2025-06-06 22:00") do # 金曜の夜
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 7, 9, 0) # 翌土曜
        end
      end

      it "平日は配信しない（次の土日を探す）" do
        setting = build_setting(delivery_time_1: time_9am, frequency: "weekend")
        travel_to Time.zone.parse("2025-06-09 22:00") do # 月曜の夜
          result = described_class.call(setting)
          expect(result).to eq Time.zone.local(2025, 6, 14, 9, 0) # 次の土曜
        end
      end
    end
  end
end
