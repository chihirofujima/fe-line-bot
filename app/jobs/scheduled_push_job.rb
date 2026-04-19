require "line/bot"

class ScheduledPushJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[ScheduledPushJob] 開始: #{Time.current}"

    api = Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )

    q = QuestionLoader.random
    return Rails.logger.error "[ScheduledPushJob] 問題が見つかりません" unless q

    choices = { "ア" => "", "イ" => "", "ウ" => "", "エ" => "" }
    flex = FlexBuilder.question(
      question_id:   q[:number],
      year:          q[:year],
      question_text: q[:content],
      choices:       choices,
      correct:       q[:correct_answer]
    )

    User.find_each do |user|
      request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
        to: user.line_user_id,
        messages: [
          Line::Bot::V2::MessagingApi::FlexMessage.new(
            alt_text: flex["altText"],
            contents: flex["contents"]
          )
        ]
      )
      api.push_message(push_message_request: request)
      Rails.logger.info "[ScheduledPushJob] 送信: #{user.line_user_id}"
    end

    Rails.logger.info "[ScheduledPushJob] 完了"
  end
end
