namespace :line do
  desc "リッチメニューを作成してデフォルトに設定"
  task create_rich_menu: :environment do
    require "net/http"
    require "json"

    token = ENV.fetch("LINE_CHANNEL_TOKEN")

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
  end

  desc "既存のリッチメニューをデフォルトに設定"
  task set_default_rich_menu: :environment do
    require "net/http"
    token = ENV.fetch("LINE_CHANNEL_TOKEN")
    rich_menu_id = "richmenu-070198a9129ae93d84047152dd7b9541"

    uri = URI("https://api.line.me/v2/bot/user/all/richmenu/#{rich_menu_id}")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"] = "application/json"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res = http.request(req)
    puts "デフォルト設定: #{res.code} #{res.body}"
  end

  desc "画像アップロード → リッチメニュー作成 → デフォルト設定を一括実行"
  task setup_rich_menu: :environment do
    require "net/http"
    require "json"

    token = ENV.fetch("LINE_CHANNEL_TOKEN")
    image_path = Rails.root.join("public/images/rich_menu.png")

    puts "=== リッチメニュー作成 ==="
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

    http = Net::HTTP.new("api.line.me", 443)
    http.use_ssl = true

    req = Net::HTTP::Post.new("/v2/bot/richmenu")
    req["Authorization"] = "Bearer #{token}"
    req["Content-Type"] = "application/json"
    req.body = menu.to_json

    res = http.request(req)
    body = JSON.parse(res.body)
    puts "作成結果: #{res.code} #{body}"

    unless res.code == "200"
      puts "リッチメニュー作成失敗。終了します。"
      exit 1
    end

    rich_menu_id = body["richMenuId"]
    puts "richMenuId: #{rich_menu_id}"

    puts "=== 画像アップロード ==="
    image_data = File.binread(image_path)

    http2 = Net::HTTP.new("api-data.line.me", 443)
    http2.use_ssl = true

    req2 = Net::HTTP::Post.new("/v2/bot/richmenu/#{rich_menu_id}/content")
    req2["Authorization"] = "Bearer #{token}"
    req2["Content-Type"] = "image/png"
    req2.body = image_data

    res2 = http2.request(req2)
    puts "画像アップロード結果: #{res2.code} #{res2.body}"

    unless res2.code == "200"
      puts "画像アップロード失敗。終了します。"
      exit 1
    end

    puts "=== デフォルト設定 ==="
    req3 = Net::HTTP::Post.new("/v2/bot/user/all/richmenu/#{rich_menu_id}")
    req3["Authorization"] = "Bearer #{token}"
    req3["Content-Type"] = "application/json"

    res3 = http.request(req3)
    puts "デフォルト設定結果: #{res3.code} #{res3.body}"
    puts "完了！richMenuId=#{rich_menu_id}"
  end
end
