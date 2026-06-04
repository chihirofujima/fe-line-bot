class AnswerRecorder
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
      last_answered_at: Time.current
    )

    answer.save!
    answer
  end
end
