class ShareToken < ApplicationRecord
  belongs_to :user

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  validates :token, presence: true, uniqueness: true

  EXPIRATION_PERIOD = 30.days

  def expired?
    expires_at < Time.current
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= EXPIRATION_PERIOD.from_now
  end
end
