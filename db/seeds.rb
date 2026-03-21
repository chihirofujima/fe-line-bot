# 基本情報技術者試験 過去問データ

require 'csv'

CSV.foreach(Rails.root.join('db/questions.csv'), headers: true) do |row|
  Question.find_or_initialize_by(number: row['number'].to_i).tap do |q|
    q.content        = row['content']
    q.correct_answer = row['correct_answer']
    q.image_url      = row['image_url'].presence
    q.choice_1       = row['choice_1']
    q.choice_2       = row['choice_2']
    q.choice_3       = row['choice_3']
    q.choice_4       = row['choice_4']
    q.save!
  end
end
