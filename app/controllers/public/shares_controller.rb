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

    def og_image
      share_token = ShareToken.find_by(token: params[:token])
      return head :not_found unless share_token

      data = Liff::HistoryAggregator.new(share_token.user).call
      stats = data[:summary]

      png = Rails.cache.fetch("ogp_image/#{share_token.token}/#{Date.current}") do
        Ogp::ImageGenerator.new(stats).call
      end

      send_data png, type: "image/png", disposition: "inline"
    end
  end
end
