class Liff::SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    id_token = params[:id_token]

    if id_token.blank?
      return render json: { error: "IDトークンがありません" }, status: :bad_request
    end

    # LINE APIでIDトークンを検証する
    response = Faraday.post("https://api.line.me/oauth2/v2.1/verify") do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form(
        id_token: id_token,
        client_id: ENV.fetch("LIFF_CHANNEL_ID")
      )
    end

    result = JSON.parse(response.body)

    if response.status != 200
      return render json: { error: "トークンの検証に失敗しました" }, status: :unauthorized
    end

    if result["sub"].blank?
      return render json: { error: "LINEユーザーIDを取得できませんでした" }, status: :unauthorized
    end

    session[:line_user_id] = result["sub"] # "sub" がLINEユーザーID

    render json: { ok: true }
  end
end
