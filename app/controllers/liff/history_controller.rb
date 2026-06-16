class Liff::HistoryController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_liff_user

  def index
    render layout: "liff"
  end

  def data
    render json: Liff::HistoryAggregator.new(@current_user).call
  end

  private

  def authenticate_liff_user
    line_user_id = request.headers["X-Line-User-Id"]
    @current_user = User.find_by(line_user_id: line_user_id)
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end
end
