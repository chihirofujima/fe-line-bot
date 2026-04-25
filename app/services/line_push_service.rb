class LinePushService
  def self.push_daily_question
    q = Question.order("RANDOM()").first
    return Rails.logger.error "問題が見つかりません" unless q

    choices = {
      "ア" => q.choice_1,
      "イ" => q.choice_2,
      "ウ" => q.choice_3,
      "エ" => q.choice_4
    }

    flex = FlexBuilder.question(
      question_id:   q.id,
      question_text: q.content,
      choices:       choices,
      correct:       q.correct_answer
    )

    client = Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )

    request = Line::Bot::V2::MessagingApi::BroadcastRequest.new(
      messages: [
        Line::Bot::V2::MessagingApi::FlexMessage.new(
          alt_text: flex["altText"],
          contents: flex["contents"]
        )
      ]
    )

    response = client.broadcast(broadcast_request: request)
    Rails.logger.info "LINE broadcast result: #{response.inspect}"
  rescue => e
    Rails.logger.error "LinePushService error: #{e.class} #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
