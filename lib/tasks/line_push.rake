namespace :line do
  desc "毎朝8時に問題をプッシュ配信"
  task push_daily_question: :environment do
    LinePushService.push_daily_question
  end
end
