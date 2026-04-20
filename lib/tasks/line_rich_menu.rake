namespace :line do
  desc "リッチメニューを作成してデフォルトに設定"
  task create_rich_menu: :environment do
    require "net/http"
    require "json"

    token = ENV.fetch("LINE_CHANNEL_TOKEN")
    rich_menu_id = "richmenu-e559d44168b521daa9113c14872c949e"  # 画像アップロード済みのID

    menu = {
      size: { width: 2500, height: 843 },
      selected: true,
      name: "基本情報技術者試験メニュー",
      chatBarText: "メニュー",
      areas: [
        {
          bounds: { x: 0, y: 0, width: 833, height: 843 },
          action: { type: "message", label: "問題を解く", text: "問題を解く" }
        },
        {
          bounds: { x: 833, y: 0, width: 834, height: 843 },
          action: { type: "message", label: "学習履歴", text: "学習履歴" }
        },
        {
          bounds: { x: 1667, y: 0, width: 833, height: 843 },
          action: { type: "message", label: "設定", text: "設定" }
        }
      ]
    }

    uri = URI("https://api.line.me/v2/bot/richmenu")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"] = "application/json"
    req.body = menu.to_json

    res = http.request(req)
    body = JSON.parse(res.body)
    puts "作成結果: #{res.code} #{body}"

    unless res.code == "200"
      puts "エラーで終了"
      exit 1
    end

    rich_menu_id = body["richMenuId"]
    puts "richMenuId: #{rich_menu_id}"

    uri2 = URI("https://api.line.me/v2/bot/user/all/richmenu/#{rich_menu_id}")
    req2 = Net::HTTP::Post.new(uri2)
    req2["Authorization"] = "Bearer #{token}"
    req2["Content-Type"] = "application/json"

    res2 = http.request(req2)
    puts "デフォルト設定レスポンス詳細: #{res2.code} #{res2.body}"
    puts "完了！richMenuId=#{rich_menu_id} を保存しておいてください。"
  end  # ← create_rich_menu の end

  # ↓ create_rich_menu の外、namespace の中
  desc "既存のリッチメニューをデフォルトに設定"
  task set_default_rich_menu: :environment do
    require "net/http"
    token = ENV.fetch("LINE_CHANNEL_TOKEN")
    rich_menu_id = "richmenu-e559d44168b521daa9113c14872c949e"

    uri = URI("https://api.line.me/v2/bot/user/all/richmenu/#{rich_menu_id}")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"] = "application/json"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res = http.request(req)
    puts "デフォルト設定: #{res.code} #{res.body}"
  end

end  # ← namespace の end