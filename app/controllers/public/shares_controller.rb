module Public
  class SharesController < ApplicationController
    layout "public" # liff.js を読み込まない専用レイアウト

    def show
      @share_token = ShareToken.find_by(token: params[:token])

      unless @share_token
        return render "not_found", status: :not_found
      end

      if @share_token.expired?
        return render "expired", status: :gone
      end

      snapshot = @share_token.snapshot_data.symbolize_keys

      @stats           = snapshot.slice(:accuracy_rate, :total_study_days, :mastery_rate, :total_answers)
      @daily_stats     = snapshot[:daily_stats]
      @mastery_history = snapshot[:mastery_history]
    end

    def og_image
      share_token = ShareToken.find_by(token: params[:token])
      return head :not_found unless share_token
      return head :gone if share_token.expired?

      # --- 動的にステータス画像を生成する処理---
      # stats = share_token.snapshot_data.symbolize_keys
      #
      # png = Rails.cache.fetch("ogp_image/#{share_token.token}/#{share_token.created_at.to_date}") do
      #   Ogp::ImageGenerator.new(stats).call
      # end
      #
      # send_data png, type: "image/png", disposition: "inline"

      # --- 静的なOGP画像を返す処理---
      send_file Rails.root.join("public/images/ogp_default.png"),
                type: "image/png",
                disposition: "inline"
    end
  end
end
