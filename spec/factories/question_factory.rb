FactoryBot.define do
  factory :question do
    sequence(:number) { |n| n }
    content { "テスト問題文です。" }
    image_url { nil }
    choice_1 { "選択肢1" }
    choice_2 { "選択肢2" }
    choice_3 { "選択肢3" }
    choice_4 { "選択肢4" }
    correct_answer { "1" }
    explanation_url { "https://example.com/explanation" }
    year { 2023 }
  end
end
