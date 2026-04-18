# app/jobs/line_push_job.rb
class LinePushJob < ApplicationJob
  queue_as :default

  def perform
    # 通知有効なユーザーを取得
    users = User.where(line_notification: true)

    users.find_each do |user|
      send_push_message(user)
    rescue => e
      # 1ユーザーの失敗で全体を止めない
      Rails.logger.error("LINE push failed for user #{user.id}: #{e.message}")
    end
  end

  private

  def send_push_message(user)
    client = Line::Bot::Client.new do |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token  = ENV["LINE_CHANNEL_TOKEN"]
    end

    message = {
      type: "text",
      text: "今日の問題です！"
    }

    response = client.push_message(user.line_user_id, message)
    
    unless response.is_a?(Net::HTTPOK)
      raise "LINE API error: #{response.body}"
    end
  end
end