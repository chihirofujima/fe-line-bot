require 'csv'

# r05 → "05_menjo", r06 → "06_haru" or "06_aki" など
# CSVにexplanation_urlが入っていない場合の自動生成ルール
YEAR_PATH = {
  "r05" => "05_menjo"
  # 今後追加する場合はここに追記
  # "r06" => "06_haru",
}.freeze

Dir[Rails.root.join('db/csv/*.csv')].each do |file|
  year = File.basename(file, '.csv')
  url_path = YEAR_PATH[year] || year  # 対応表になければファイル名をそのまま使う
  Rails.logger.info "Importing #{File.basename(file)}..."

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
end
