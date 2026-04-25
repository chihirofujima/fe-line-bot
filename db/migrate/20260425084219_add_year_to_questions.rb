class AddYearToQuestions < ActiveRecord::Migration[7.2]
  def change
    add_column :questions, :year, :string
  end
end
