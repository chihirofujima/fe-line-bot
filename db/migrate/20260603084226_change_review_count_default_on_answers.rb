class ChangeReviewCountDefaultOnAnswers < ActiveRecord::Migration[7.2]
  def change
    change_column_default :answers, :review_count, from: nil, to: 0
    Answer.where(review_count: nil).update_all(review_count: 0)
  end
end
