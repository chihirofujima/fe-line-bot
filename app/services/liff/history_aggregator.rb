class Liff::HistoryAggregator
  def initialize(user)
    @user = user
    @answers = user.answers
                   .select(:is_correct, :created_at, :question_id, :review_count)
                   .order(:created_at)
  end

  def call
    { summary: build_summary }
  end

  private

  def build_summary
    total   = @answers.size
    correct = @answers.count(&:is_correct)

    mastered_count        = @user.answers
                                 .group(:question_id)
                                 .having('MAX(review_count) >= 3')
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

  def study_dates
    @study_dates ||= @answers.map { |a| a.created_at.to_date }.to_set
  end
end