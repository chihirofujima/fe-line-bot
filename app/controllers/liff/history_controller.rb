class Liff::HistoryController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout "liff"
  before_action :set_user, except: [ :index ]

  def index
  end

  def data
    render json: Liff::HistoryAggregator.new(@user).call
  end

  def create_share_token
    aggregate_result = Liff::HistoryAggregator.new(@user).call
    summary = aggregate_result[:summary]

    share_token = @user.share_tokens.create!(
      snapshot_data: {
        accuracy_rate: summary[:accuracy_rate],
        total_study_days: summary[:total_study_days],
        mastery_rate: summary[:mastery_rate],
        total_answers: summary[:total_answers]
    }
  )

  render json: { share_url: "#{request.base_url}/share/#{share_token.token}" }
end

private

  def set_user
    @user= User.find_by(line_user_id: session[:line_user_id])

    render json: { error: "ユーザーが見つかりません" }, status: :not_found unless @user
  end
end
