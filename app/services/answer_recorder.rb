class AnswerRecorder
  MAX_REVIEW_LEVEL = 5
  MIN_REVIEW_LEVEL = 0

  def self.call(user:, question:, answer_choice:, is_correct:)
    new(
      user: user,
      question: question,
      answer_choice: answer_choice,
      is_correct: is_correct
    ).call
  end

  def initialize(user:, question:, answer_choice:, is_correct:)
    @user = user
    @question = question
    @answer_choice = answer_choice
    @is_correct = is_correct
  end

  def call
    answer = Answer.find_or_initialize_by(
      user_id: @user.id,
      question_id: @question.id
    )

    answer.delivered_at ||= Time.current

    answer.assign_attributes(
      answer_choice: @answer_choice,
      is_correct: @is_correct,
      last_answered_at: Time.current,
      review_level: next_review_level(answer)
    )

    answer.save!
    answer
  end

  private

  def next_review_level(answer)
    current = answer.review_level.to_i

    if @is_correct
      [ current + 1, MAX_REVIEW_LEVEL ].min
    else
      [ current - 1, MIN_REVIEW_LEVEL ].max
    end
  end
end
