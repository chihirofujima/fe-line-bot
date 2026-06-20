module Public
  class SharesController < ApplicationController
    layout "public" # liff.js を読み込まない専用レイアウト

    def show
      @share_token = ShareToken.find_by(token: params[:token])

      unless @share_token
        return render "not_found", status: :not_found
      end

      user = @share_token.user
      data = Liff::HistoryAggregator.new(user).call

      @stats            = data[:summary]
      @daily_stats      = data[:daily_stats]
      @mastery_history  = data[:mastery_history]
    end
  end
end
