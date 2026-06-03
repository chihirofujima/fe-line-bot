class Answer < ApplicationRecord
  # 今日以前にレビュー予定のものを取得
  scope :due_for_review, -> { where("next_review_at <= ? OR next_review_at IS NULL", Time.current) }
  scope :by_next_review, -> { order(:next_review_at) }

  def needs_review?
    next_review_at.nil? || next_review_at <= Time.current
  end

  def apply_review!(quality)
    service = SpacedRepetitionService.new(self)
    service.calculate_next_review(quality)
    save!
  end
end
