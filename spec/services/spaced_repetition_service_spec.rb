require "rails_helper"

RSpec.describe SpacedRepetitionService do
  # テスト用のanswerオブジェクトを毎回リセット
  let(:answer) do
    Answer.new(
      review_count: 0,
      interval_days: 1,
      easiness_factor: 2.5
    )
  end

  describe ".call" do
    context "正解したとき(quality: 4)" do
      it "review_countが増加すること" do
        expect {
          SpacedRepetitionService.call(answer, 4)
        }.to change { answer.review_count }.by(1)
      end

      it "next_review_atが未来に設定されること" do
        SpacedRepetitionService.call(answer, 4)
        expect(answer.next_review_at).to be > Time.current
      end

      it "easiness_factorが2.5以上を維持すること" do
        SpacedRepetitionService.call(answer, 4)
        expect(answer.easiness_factor).to be >= 2.5
      end
    end

    context "不正解のとき（quality: 1）" do
      it "review_countが0にリセットされること" do
        answer.review_count = 3
        SpacedRepetitionService.call(answer, 1)
        expect(answer.review_count).to eq 0
      end

      it "interval_daysが1にリセットされること" do
        answer.interval_days = 6
        SpacedRepetitionService.call(answer, 1)
        expect(answer.interval_days).to eq 1
      end

      it "easiness_factorが下がること" do
        original_ef = answer.easiness_factor
        SpacedRepetitionService.call(answer, 1)
        expect(answer.easiness_factor).to be < original_ef
      end
    end

    context "easiness_factorの下限（MIN: 1.3）" do
      it "何度不正解でも1.3を下回らないこと" do
        answer.easiness_factor = 1.3
        10.times { SpacedRepetitionService.call(answer, 0) }
        expect(answer.easiness_factor).to be >= 1.3
      end
    end

    context "review_countによるinterval_daysの変化" do
      it "review_count: 0のとき interval_daysが1になること" do
        answer.review_count = 0
        SpacedRepetitionService.call(answer, 4)
        expect(answer.interval_days).to eq 1
      end

      it "review_count: 1のとき interval_daysが6になること" do
        answer.review_count = 1
        SpacedRepetitionService.call(answer, 4)
        expect(answer.interval_days).to eq 6
      end

      it "review_count: 2以上のとき interval_daysが計算値になること" do
        answer.review_count = 2
        answer.interval_days = 6
        SpacedRepetitionService.call(answer, 4)
        expect(answer.interval_days).to eq (6 * 2.5).round
      end
    end
  end
end
