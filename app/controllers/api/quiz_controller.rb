class Api::QuizController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_cron_token

  def deliver
    ScheduledPushJob.perform_now  # perform_laterからperform_nowに変更
    render json: { status: 'ok' }
  end

  private

  def verify_cron_token
    token = request.headers["Authorization"]&.split("Bearer ")&.last
    unless token && ActiveSupport::SecurityUtils.secure_compare(
      token,
      ENV.fetch("CRON_SECRET_TOKEN")
    )
      render json: { error: "unauthorized" }, status: :unauthorized
    end
  end
end
