require 'line/bot'

class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    begin
      events = parser.parse(body: body, signature: signature)
    rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
      return head :bad_request
    end

    events.each do |event|
      case event
      when Line::Bot::V2::Webhook::MessageEvent
        case event.message
        when Line::Bot::V2::Webhook::TextMessageContent
          reply_request = Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
            reply_token: event.reply_token,
            messages: [
              Line::Bot::V2::MessagingApi::TextMessage.new(text: "[ECHO] #{event.message.text}")
            ]
          )
          client.reply_message(reply_message_request: reply_request)
        end
      end
    end

    head :ok
  end

  private

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