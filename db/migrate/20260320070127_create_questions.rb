class CreateQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :questions do |t|
      t.integer :number
      t.text :content
      t.string :image_url
      t.string :choice_1
      t.string :choice_2
      t.string :choice_3
      t.string :choice_4
      t.integer :correct_answer
      t.string :explanation_url

      t.timestamps
    end
  end
end
