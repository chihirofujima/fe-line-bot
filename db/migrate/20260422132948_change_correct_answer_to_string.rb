class ChangeCorrectAnswerToString < ActiveRecord::Migration[7.2]
  def change
    change_column :questions, :correct_answer, :string
  end
end
