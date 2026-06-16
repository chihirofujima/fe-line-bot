class Liff::HistoryController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout "liff"

  def index
  end

  def data
    user = User.find_by(line_user_id: session[:line_user_id])
    return render json: { error: "ユーザーが見つかりません" }, status: :not_found unless user

    render json: Liff::HistoryAggregator.new(user).call
  end
end
