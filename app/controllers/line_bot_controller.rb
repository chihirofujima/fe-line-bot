require "line/bot"

class LineBotController < ApplicationController
  protect_from_forgery except: [ :callback ]

  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]

    begin
      events = parser.parse(body: body, signature: signature)
    rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
      return head :bad_request
    end

    events.each do |event|
      case event
      when Line::Bot::V2::Webhook::FollowEvent
        User.find_or_create_by(line_user_id: event.source.user_id)

      when Line::Bot::V2::Webhook::MessageEvent
        case event.message
        when Line::Bot::V2::Webhook::TextMessageContent
          handle_message(event)
        end

      when Line::Bot::V2::Webhook::PostbackEvent
        handle_postback(event)
      end
    end

    head :ok
  end

  private

  # テキスト受信 → ランダムに問題を出題
  def handle_message(event)
    begin
      q             = QuestionLoader.random
      choices       = QuestionLoader.parse_choices(q[:content])
      question_text = q[:content].split("\n").first

      flex = FlexBuilder.question(
        question_id:   q[:number],
        year:          q[:year],
        question_text: question_text,
        choices:       choices,
        correct:       q[:correct_answer]
      )

      reply_flex(event.reply_token, flex)
    rescue => e
      Rails.logger.error "handle_message error: #{e.class} #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      reply_text(event.reply_token, "エラー: #{e.message}")
    end
  end

  # postback受信 → 正誤判定 or 次の問題
  def handle_postback(event)
    params = URI.decode_www_form(event.postback.data).to_h

    case params["action"]
    when "next"
      handle_message(event)
    when "end"
      reply_text(event.reply_token, "お疲れ様でした！またいつでも挑戦してね。")
    else
      user_answer = params["answer"]
      question_id = params["question_id"].to_i
      year        = params["year"]
      correct     = params["correct"]
      is_correct  = user_answer == correct

      q    = QuestionLoader.find(year: year, number: question_id)
      flex = FlexBuilder.result(
        is_correct:      is_correct,
        correct:         correct,
        question_id:     question_id,
        explanation_url: q&.dig(:explanation_url)
      )

      reply_flex(event.reply_token, flex)
    end
  end

  def reply_flex(reply_token, flex)
    request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: reply_token,
      messages: [
        Line::Bot::V2::MessagingApi::FlexMessage.new(
          alt_text: flex[:altText],
          contents: flex[:contents]
        )
      ]
    )
    client.reply_message(reply_message_request: request)
  end

  def reply_text(reply_token, text)
    request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: reply_token,
      messages: [
        Line::Bot::V2::MessagingApi::TextMessage.new(text: text)
      ]
    )
    client.reply_message(reply_message_request: request)
  end

  def client
    @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )
  end

  def parser
    @parser ||= Line::Bot::V2::WebhookParser.new(
      channel_secret: ENV.fetch("LINE_CHANNEL_SECRET")
    )
  end
end
