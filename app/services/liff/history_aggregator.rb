class Liff::HistoryAggregator
  def initialize(user)
    @user = user
    @answers = user.answers
                   .select(:is_correct, :created_at, :question_id, :review_count)
                   .order(:created_at)
  end

  def call
    { summary: build_summary,
      daily_stats:     build_daily_stats,
      mastery_history: build_mastery_history
    }
  end

  private

  def build_summary
    total   = @answers.size
    correct = @answers.count(&:is_correct)

    mastered_count        = @user.answers
                                 .group(:question_id)
                                 .having("MAX(review_count) >= 3")
                                 .count
                                 .size
    total_questions_tried = @answers.map(&:question_id).uniq.size

    {
      total_answers:         total,
      accuracy_rate:         total.positive? ? (correct.to_f / total * 100).round(1) : 0,
      total_study_days:      study_dates.size,
      today_answers:         @answers.count { |a| a.created_at.to_date == Date.today },
      mastery_rate:          total_questions_tried.positive? ? (mastered_count.to_f / total_questions_tried * 100).round(1) : 0,
      mastered_count:        mastered_count,
      total_questions_tried: total_questions_tried
    }
  end

  # 草グリッド用：過去6ヶ月の日付ごとの回答数
  # 例: { "2026-04-01" => 5, "2026-04-02" => 3 }
  def build_daily_stats
    @user.answers
         .where(created_at: 26.weeks.ago.beginning_of_day..)
         .group("DATE(created_at)")
         .count
  end

  # 定着度推移グラフ用：過去26週分の週末時点の定着率
  # 例: [{ date: "3/15", mastery_rate: 10.0 }, ...]
  def build_mastery_history
    (0..12).map do |weeks_ago|
      week_end   = weeks_ago.weeks.ago.end_of_week

      tried = @user.answers
                   .where(created_at: ..week_end)
                   .distinct
                   .count(:question_id)

      mastered = @user.answers
                      .where(created_at: ..week_end)
                      .group(:question_id)
                      .having("MAX(review_count) >= 3")
                      .count
                      .size

      rate = tried.positive? ? (mastered.to_f / tried * 100).round(1) : 0.0

      { date: week_end.strftime("%-m/%-d"), mastery_rate: rate }
    end.reverse
  end

  def study_dates
    @study_dates ||= @answers.map { |a| a.created_at.to_date }.to_set
  end
end
