require 'csv'

Dir[Rails.root.join('db/csv/*.csv')].each do |file|
  url_path = File.basename(file, '.csv')
  Rails.logger.info "Importing #{url_path}..."

  CSV.foreach(file, headers: true, encoding: 'BOM|UTF-8') do |row|
    number = row['number'].to_i

    Question.find_or_initialize_by(number: number).tap do |q|
      q.content         = row['content']
      q.correct_answer  = row['correct_answer']
      q.image_url       = row['image_url'].presence
      q.choice_1        = row['choice_1']
      q.choice_2        = row['choice_2']
      q.choice_3        = row['choice_3']
      q.choice_4        = row['choice_4']
      q.explanation_url = row['explanation_url'].presence&.strip ||
        "https://www.fe-siken.com/kakomon/#{url_path}/q#{number}.html"
      q.save!
    end
  end

  puts "#{url_path}: インポート完了（合計 #{Question.count} 件）"
end
