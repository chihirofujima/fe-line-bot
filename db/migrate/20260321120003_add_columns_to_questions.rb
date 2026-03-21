class AddColumnsToQuestions < ActiveRecord::Migration[7.2]
  def change
    add_column :questions, :number, :integer
  end
end