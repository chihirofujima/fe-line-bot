require "rails_helper"

#NOTE:
# - 日付・週の境界に依存するロジック（build_daily_stats, build_mastery_history）が多いため、
#   travel_to で「現在時刻」を固定し、テストを再現可能にしています。
RSpec.describe Liff::HistoryAggregator do
  let(:user)      { create(:user) }
  let(:question1) { create(:question) }
  let(:question2) { create(:question) }

  subject(:aggregator) { described_class.new(user) }

  # 2026-07-03(金) 12:00 に時刻を固定してテストする
  around do |example|
    travel_to(Time.zone.local(2026, 7, 3, 12, 0, 0)) { example.run }
  end

  describe "#call" do
    it "summary / daily_stats / mastery_history の3キーを持つハッシュを返す" do
      result = aggregator.call

      expect(result.keys).to contain_exactly(:summary, :daily_stats, :mastery_history)
    end
  end

  describe "#build_summary（#call経由）" do
    context "回答が1件もない場合" do
      it "ゼロ除算を起こさず、すべて0で返す" do
        summary = aggregator.call[:summary]

        expect(summary).to eq(
          total_answers: 0,
          accuracy_rate: 0,
          total_study_days: 0,
          today_answers: 0,
          mastery_rate: 0,
          mastered_count: 0,
          total_questions_tried: 0
        )
      end
    end

    context "回答が複数件あり、正誤・習得状況が混在する場合" do
      before do
        # question1: 2件回答（1正解・1不正解）、review_countは3未満 → 未習得
        create(:answer, user: user, question: question1, is_correct: true,  review_count: 1, created_at: 2.days.ago)
        create(:answer, user: user, question: question1, is_correct: false, review_count: 1, created_at: 1.day.ago)
        # question2: 1件回答（正解）、review_countが3以上 → 習得済み
        create(:answer, user: user, question: question2, is_correct: true,  review_count: 3, created_at: Time.current)
      end

      it "総回答数を正しく集計する" do
        expect(aggregator.call[:summary][:total_answers]).to eq(3)
      end

      it "正答率を小数第1位まで正しく計算する" do
        # 2/3 = 66.66... → 66.7
        expect(aggregator.call[:summary][:accuracy_rate]).to eq(66.7)
      end

      it "学習日数をユニークな日付数で集計する" do
        expect(aggregator.call[:summary][:total_study_days]).to eq(3)
      end

      it "今日作成された回答のみをtoday_answersとして集計する" do
        expect(aggregator.call[:summary][:today_answers]).to eq(1)
      end

      it "review_countの最大値が3以上の問題のみをmastered_countとして集計する" do
        expect(aggregator.call[:summary][:mastered_count]).to eq(1)
      end

      it "回答した問題のユニーク数をtotal_questions_triedとして集計する" do
        expect(aggregator.call[:summary][:total_questions_tried]).to eq(2)
      end

      it "習得済み問題数 / 挑戦した問題数で定着率を計算する" do
        # 1 / 2 * 100 = 50.0
        expect(aggregator.call[:summary][:mastery_rate]).to eq(50.0)
      end
    end
  end

  describe "#build_daily_stats（#call経由）" do
    it "26週間以内の回答を日付ごとの件数として集計する" do
      create(:answer, user: user, question: question1, created_at: 1.week.ago)
      create(:answer, user: user, question: question1, created_at: 1.week.ago)
      create(:answer, user: user, question: question1, created_at: Time.current)

      daily_stats = aggregator.call[:daily_stats]

      expect(daily_stats[1.week.ago.to_date]).to eq(2)
      expect(daily_stats[Date.current]).to eq(1)
    end

    it "26週間より前の回答は集計対象から除外する" do
      create(:answer, user: user, question: question1, created_at: 27.weeks.ago)

      daily_stats = aggregator.call[:daily_stats]

      expect(daily_stats[27.weeks.ago.to_date]).to be_nil
    end
  end

  describe "#build_mastery_history（#call経由）" do
    it "0週前〜12週前の13週分のデータを返す" do
      mastery_history = aggregator.call[:mastery_history]

      expect(mastery_history.size).to eq(13)
    end

    it "日付が古い順（昇順）に並んでいる" do
      mastery_history = aggregator.call[:mastery_history]
      dates = mastery_history.map { |h| h[:date] }

      expect(dates.first).to eq(12.weeks.ago.end_of_week.strftime("%-m/%-d"))
      expect(dates.last).to eq(Time.current.end_of_week.strftime("%-m/%-d"))
    end

    it "各要素がdateとmastery_rateのキーを持つ" do
      mastery_history = aggregator.call[:mastery_history]

      expect(mastery_history).to all(include(:date, :mastery_rate))
    end

    it "対象週までに回答がまだない場合、mastery_rateは0.0になる" do
      mastery_history = aggregator.call[:mastery_history]

      expect(mastery_history.first[:mastery_rate]).to eq(0.0)
    end

    it "その週末時点までの累積データを元に定着率を計算する" do
      create(:answer, user: user, question: question1, review_count: 3, created_at: 3.weeks.ago)
      create(:answer, user: user, question: question2, review_count: 1, created_at: 3.weeks.ago)

      mastery_history = aggregator.call[:mastery_history]
      target_date = 3.weeks.ago.end_of_week.strftime("%-m/%-d")
      target = mastery_history.find { |h| h[:date] == target_date }

      # tried: 2件, mastered: 1件 → 50.0
      expect(target[:mastery_rate]).to eq(50.0)
    end

    it "対象週より後に作成された回答は、その週の集計に含めない（未来データの混入防止）" do
      # 5週間前の時点ではまだ存在しない回答（今日作成）
      create(:answer, user: user, question: question1, review_count: 3, created_at: Time.current)

      mastery_history = aggregator.call[:mastery_history]
      target_date = 5.weeks.ago.end_of_week.strftime("%-m/%-d")
      target = mastery_history.find { |h| h[:date] == target_date }

      expect(target[:mastery_rate]).to eq(0.0)
    end
  end

  describe "#study_dates（メモ化・privateメソッド）" do
    it "同一インスタンス内では再計算されず、同じSetオブジェクトを返す" do
      create(:answer, user: user, question: question1, created_at: Time.current)

      first_call  = aggregator.send(:study_dates)
      second_call = aggregator.send(:study_dates)

      expect(first_call).to equal(second_call) # object_idが同一＝メモ化されている
    end
  end
end
