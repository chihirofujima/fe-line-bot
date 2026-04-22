require 'csv'

# db/csv/以下の全CSVファイルを自動で読み込む
Dir[Rails.root.join('db/csv/*.csv')].each do |file|
  Rails.logger.info "Importing #{File.basename(file)}..."

  CSV.foreach(file, headers: true, encoding: 'BOM|UTF-8') do |row|
    Question.find_or_initialize_by(number: row['number'].to_i).tap do |q|
      q.content         = row['content']
      q.correct_answer  = row['correct_answer']
      q.image_url       = row['image_url'].presence
      q.choice_1        = row['choice_1']
      q.choice_2        = row['choice_2']
      q.choice_3        = row['choice_3']
      q.choice_4        = row['choice_4']
      q.explanation_url = row['explanation_url']
      q.save!
    end
  end
end
