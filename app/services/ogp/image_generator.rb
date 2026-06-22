class Ogp::ImageGenerator
  TEMPLATE_PATH = Rails.root.join("app/assets/images/ogp_template.png")

  def initialize(stats)
    @stats = stats # 正答率・定着率などのハッシュ
  end

  def call
    image = MiniMagick::Image.open(TEMPLATE_PATH)

    image.combine_options do |c|
      c.gravity "NorthWest"
      c.pointsize 60
      c.fill "white"
      c.font "Noto-Sans-CJK-JP-Bold"
      c.draw "text 80,200 'fetokkuユーザーの学習記録'"
      c.draw "text 80,300 '正答率: #{@stats[:accuracy_rate]}%'"
      c.draw "text 80,400 '定着率: #{@stats[:mastery_rate]}%'"
    end

    image.to_blob
  end
end
