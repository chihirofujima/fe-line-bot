class AddSpacedRepetitionToAnswers < ActiveRecord::Migration[7.0]
  def change
    rename_column :answers, :review_level, :review_count
    add_column :answers, :next_review_at, :datetime
    add_column :answers, :interval_days, :integer, default: 1, null: false
    add_column :answers, :easiness_factor, :float, default: 2.5, null: false
  end
end
