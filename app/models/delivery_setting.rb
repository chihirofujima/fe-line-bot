class DeliverySetting < ApplicationRecord
  belongs_to :user

  enum :frequency, { daily: "daily", weekday: "weekday", weekend: "weekend" }

  validates :frequency, presence: true
  validates :delivery_time_1, presence: true
  validates :user_id, uniqueness: true
end