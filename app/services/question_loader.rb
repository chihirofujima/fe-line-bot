require 'csv'
 
module QuestionLoader
  DB_PATH = Rails.root.join('db')
 
  def self.all
    @questions ||= Dir.glob("#{DB_PATH}/*.csv").flat_map do |csv_path|
      year = File.basename(csv_path)[/\d{4}/]
      CSV.foreach(csv_path, headers: true, encoding: 'BOM|UTF-8').map do |row|
        {
          year:            year,
          number:          row['number'].to_i,
          content:         row['content'],
          correct_answer:  row['correct_answer'],
          image_url:       row['image_url'],
          explanation_url: row['explanation_url']
        }
      end
    end
  end
 
  def self.random
    all.sample
  end
 
  def self.find(year:, number:)
    all.find { |q| q[:year] == year && q[:number] == number }
  end
 
  def self.parse_choices(content)
    content.split("\n").each_with_object({}) do |line, hash|
      hash[$1] = $2.strip if line =~ /^([アイウエ])\s+(.*)/
    end
  end
end
 