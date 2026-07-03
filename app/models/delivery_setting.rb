class DeliverySetting < ApplicationRecord
  belongs_to :user

  enum :frequency, { daily: "daily", weekday: "weekday", weekend: "weekend" }

  validates :frequency, presence: true
  validates :delivery_time_1, presence: true
  validates :user_id, uniqueness: true
  validate :delivery_times_must_differ

  private

  def delivery_times_must_differ
    return if delivery_time_2.blank?
    if delivery_time_1 == delivery_time_2
      errors.add(:delivery_time_2, "は配信時間①と異なる時刻を設定してください")
    end
  end
end
