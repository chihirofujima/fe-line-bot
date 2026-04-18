# app/services/line_push_service.rb
class LinePushService
  LINE_API_ENDPOINT = "https://api.line.me/v2/bot/message/broadcast"

  def self.push_daily_question
    question = Question.order("RANDOM()").first

    message = build_message(question)
    send_push(message)
  end

  private

  def self.build_message(question)
    {
      messages: [
        {
          type: "text",
          text: "📚 本日の基本情報技術者試験問題\n\n#{question.body}\n\n" \
                "A. #{question.choice_a}\n" \
                "B. #{question.choice_b}\n" \
                "C. #{question.choice_c}\n" \
                "D. #{question.choice_d}"
        },
        {
          type: "template",
          altText: "回答してください",
          template: {
            type: "buttons",
            text: "答えを選んでください",
            actions: [
              { type: "postback", label: "A", data: "answer=A&question_id=#{question.id}" },
              { type: "postback", label: "B", data: "answer=B&question_id=#{question.id}" },
              { type: "postback", label: "C", data: "answer=C&question_id=#{question.id}" },
              { type: "postback", label: "D", data: "answer=D&question_id=#{question.id}" }
            ]
          }
        }
      ]
    }
  end

  def self.send_push(body)
    uri = URI(LINE_API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{ENV['LINE_CHANNEL_ACCESS_TOKEN']}"
    request.body = body.to_json

    response = http.request(request)
    Rails.logger.info "LINE push result: #{response.code} #{response.body}"
  end
end
