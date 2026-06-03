class SpacedRepetitionService
  MIN_EASINESS_FACTOR = 1.3

  def self.call(answer, quality)
    new(answer).calculate_next_review(quality)
  end

  def initialize(answer)
    @answer = answer
  end

  def calculate_next_review(quality)
    if quality < 3
      @answer.review_count = 0
      @answer.interval_days = 1
    else
      @answer.interval_days = next_interval
      @answer.review_count += 1
    end

    @answer.easiness_factor = updated_easiness_factor(quality)
    @answer.next_review_at = Time.current + @answer.interval_days.days
    @answer
  end

  private

  def next_interval
    case @answer.review_count
    when 0 then 1
    when 1 then 6
    else (@answer.interval_days * @answer.easiness_factor).round
    end
  end

  def updated_easiness_factor(quality)
    ef = @answer.easiness_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    [ ef, MIN_EASINESS_FACTOR ].max
  end
end
