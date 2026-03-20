class CreateAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :answers do |t|
      t.integer :user_id
      t.integer :question_id
      t.datetime :delivered_at
      t.boolean :is_correct
      t.datetime :last_answered_at
      t.integer :review_level
      t.integer :answer_choice

      t.timestamps
    end
  end
end
