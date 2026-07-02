FactoryBot.define do
  factory :answer do
    association :user
    association :question
    answer_choice { 1 }
    is_correct { true }
    delivered_at { Time.current }
    last_answered_at { Time.current }
  end
end
