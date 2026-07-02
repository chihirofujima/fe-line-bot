FactoryBot.define do
  factory :user do
    sequence(:line_user_id) { |n| "test_line_user_id_#{n}" }
    name { "テストユーザー" }
    state { 0 }
  end
end
