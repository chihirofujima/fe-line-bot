FactoryBot.define do
  factory :delivery_setting do
    association :user
    frequency { "daily" }
    delivery_time_1 { Time.zone.parse("09:00") }
  end
end
