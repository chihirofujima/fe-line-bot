require "csv"

module QuestionLoader
  DB_PATH = Rails.root.join("db")

  def self.all
    if Rails.env.development?
      load_questions
    else
      @questions ||= load_questions
    end
  end

  def self.load_questions
    Dir.glob("#{DB_PATH}/*.csv").flat_map do |csv_path|
      year_code = extract_year_code(File.basename(csv_path))
      CSV.foreach(csv_path, headers: true, encoding: "BOM|UTF-8").map do |row|
        number = row["number"].to_i
        csv_url = row["explanation_url"] 
        {
          year:            year_code,
          number:          number,
          content:         row["content"],
          correct_answer:  row["correct_answer"],
          image_url:       row["image_url"],
          choice_1:        row["choice_1"],
          choice_2:        row["choice_2"],
          choice_3:        row["choice_3"],
          choice_4:        row["choice_4"],
          explanation_url: csv_url.present? ? csv_url : build_explanation_url(year_code: year_code, number: number)
        }
      end
    end
  end

  def self.random
    all.sample
  end

  def self.default_choices
    { "ア" => "", "イ" => "", "ウ" => "", "エ" => "" }
  end

  def self.find(year:, number:)
    all.find { |q| q[:year] == year && q[:number] == number }
  end

  private

  def self.extract_year_code(filename)
    if filename =~ /r(\d{2})_aki/i
      # 令和・秋期（旧制度）例: r01_aki → 01_aki
      "#{$1}_aki"
    elsif filename =~ /r(\d{2})/i
      # 令和・免除試験 例: r05 → 05_menjo
      "#{$1}_menjo"
    elsif filename =~ /h(\d{2})_aki/i
      # 平成・秋期 例: h30_aki → 30_aki
      "#{$1}_aki"
  else
      "unknown"
    end
  end

  def self.build_explanation_url(year_code:, number:)
    "https://www.fe-siken.com/kakomon/#{year_code}/q#{number}.html"
  end
end