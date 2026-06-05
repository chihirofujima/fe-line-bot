class DeliverQuestionJob < ApplicationJob
  queue_as :default

  REVIEW_RATIO = 0.7  # 復習70%・新問題30%

  def perform(user_id)
    user = User.find_by(id: user_id)
    return Rails.logger.warn "[DeliverQuestionJob] ユーザーが見つかりません: #{user_id}" unless user

    setting = user.delivery_setting
    return Rails.logger.warn "[DeliverQuestionJob] 配信設定がありません: #{user_id}" unless setting

    question = select_question(user)
    return Rails.logger.error "[DeliverQuestionJob] 問題が見つかりません: #{user_id}" unless question

    send_question(user, question)

    next_time = DeliveryTimeCalculator.call(setting)
    if next_time
      DeliverQuestionJob.set(wait_until: next_time).perform_later(user.id)
      Rails.logger.info "[DeliverQuestionJob] 次回スケジュール: #{user.id} at #{next_time}"
    end
  end

  private

  def select_question(user)
    if rand < REVIEW_RATIO
      # 復習問題を取得（SM-2でnext_review_atが来ているもの）
      review_question = Answer.where(user_id: user.id)
                              .due_for_review
                              .by_next_review
                              .includes(:question)
                              .first&.question
      return review_question if review_question
    end

    # 新問題を取得（未回答の問題からランダム）
    answered_ids = Answer.where(user_id: user.id).pluck(:question_id)
    new_question = Question.where.not(id: answered_ids).order("RANDOM()").first
    return new_question if new_question

    # 全問題回答済みの場合はランダム
    Question.order("RANDOM()").first
  end

  def send_question(user, question)
    choices = {
      "ア" => question.choice_1,
      "イ" => question.choice_2,
      "ウ" => question.choice_3,
      "エ" => question.choice_4
    }

    flex = FlexBuilder.question(
      question_number: question.number,
      question_text:   question.content,
      choices:         choices,
      correct:         question.correct_answer
    )

    client = Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )

    request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: user.line_user_id,
      messages: [
        Line::Bot::V2::MessagingApi::FlexMessage.new(
          alt_text: flex["altText"],
          contents: flex["contents"]
        )
      ]
    )

    client.push_message(push_message_request: request)
    Rails.logger.info "[DeliverQuestionJob] 送信完了: #{user.line_user_id}"
  rescue => e
    Rails.logger.error "[DeliverQuestionJob] 送信失敗: #{e.class} #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
