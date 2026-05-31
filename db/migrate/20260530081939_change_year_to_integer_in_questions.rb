class ChangeYearToIntegerInQuestions < ActiveRecord::Migration[7.2]
  def up
    change_column :questions, :year, :integer, using: 'year::integer'
  end

  def down
    change_column :questions, :year, :string
  end
end