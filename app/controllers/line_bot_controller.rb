require "line/bot"

class LineBotController < ApplicationController
  protect_from_forgery except: [ :callback ]

  def callback
    Rails.logger.info "=== callback start ==="
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    # 読み込んだbodyが空でないかログで確認（デバッグ用）
    Rails.logger.info "=== raw body length: #{body.length} ==="

    begin
      events = parser.parse(body: body, signature: signature)
    rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
      Rails.logger.error "=== Invalid Signature ==="
      return head :bad_request
    rescue => e
      Rails.logger.error "=== Parsing Error: #{e.message} ==="
      return head :bad_request
    end

    head :ok

    Rails.logger.info "=== events: #{events.inspect}"

    events.each do |event|
      case event
      when Line::Bot::V2::Webhook::FollowEvent
        User.find_or_create_by(line_user_id: event.source.user_id)

      when Line::Bot::V2::Webhook::MessageEvent
        case event.message
        when Line::Bot::V2::Webhook::TextMessageContent
          handle_text(event)
        end

      when Line::Bot::V2::Webhook::PostbackEvent
        handle_postback(event)
      end
    end
  end

  private

  def handle_text(event)
    text = event.message.text.strip
    case text
    when "問題を解く"
      handle_message(event)
    when "設定"
      reply_text(event.reply_token, "設定機能は準備中です。")
    else
      reply_text(event.reply_token, "下のメニューから操作してください。\n「問題を解く」で出題します！")
    end
  end
  # テキスト受信 → ランダムに問題を出題
  def handle_message(event)
    begin
      q = Question.order("RANDOM()").first

      return reply_text(event.reply_token, "問題が見つかりませんでした") unless q
      choices = {
        "ア" => q[:choice_1],
        "イ" => q[:choice_2],
        "ウ" => q[:choice_3],
        "エ" => q[:choice_4]
      }
      question_text = q[:content]

      flex = FlexBuilder.question(
        question_id:   q[:id],
        question_text: q[:content],
        choices:       choices,
        correct:       q[:correct_answer]
      )

      Rails.logger.info "=== flex: #{flex.inspect}"
      reply_flex(event.reply_token, flex)
    rescue => e
      Rails.logger.error "handle_message error: #{e.class} #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      reply_text(event.reply_token, "エラー: #{e.message}")
    end
  end

  # postback受信 → 正誤判定 or 次の問題
  def handle_postback(event)
    Rails.logger.info "=== handle_postback called ==="
    Rails.logger.info "=== postback data: #{event.postback.data}"
    params = URI.decode_www_form(event.postback.data).to_h

    case params["action"]
    when "next"
      handle_message(event)
    when "end"
      reply_text(event.reply_token, "お疲れ様でした！またいつでも挑戦してね。")
    else
      user_answer = params["answer"]
      question_id = params["question_id"].to_i
      correct     = params["correct"]
      is_correct  = user_answer == correct

      q = Question.find_by(id: question_id)

      flex = FlexBuilder.result(
        is_correct:      is_correct,
        correct:         correct,
        question_id:     question_id,
        explanation_url: q&.explanation_url
      )

      reply_flex(event.reply_token, flex)
      send_next_question_push(event.source.user_id)
    end
  end

  def reply_flex(reply_token, flex)
    request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
      reply_token: reply_token,
      messages: [
        Line::Bot::V2::MessagingApi::FlexMessage.new(
          alt_text: flex["altText"],
          contents: flex["contents"]
        )
      ]
    )
    response = client.reply_message(reply_message_request: request)
    Rails.logger.info "=== reply response: #{response.inspect}"
  rescue => e
    Rails.logger.error "=== reply_flex error: #{e.class} #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
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
