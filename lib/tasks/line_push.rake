namespace :line do
  desc "LINE定期配信"
  task push_daily_question: :environment do
    LinePushService.push_daily_question
    puts "配信完了: #{Time.current}"
  end
end
