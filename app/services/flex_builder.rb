require "uri"

module FlexBuilder
  BADGE_BG_COLOR  = "#EAF1FB" # バッジの薄い背景色
  BADGE_TEXT_COLOR = "#2E6BB5" # バッジ・正解文字の色
  PRIMARY_COLOR    = "#3E7FDC" # 「解説を見る」ボタン
  BORDER_COLOR     = "#D9E2EC" # 「次の問題へ」の枠線
  GRAY_BG          = "#E3E6EA" # 「終了する」の背景

  def self.question(question_number:, question_text:, choices:, correct:,
                     year:, subject: "科目A")
    period = year.to_i <= 2019 ? "秋期" : nil
    source_text = [ "出典：IPA FE試験 #{year}年", period, subject, "問#{question_number}" ].compact.join(" ")

    rows = []
    choices.each_with_index do |(label, text), i|
      rows << {
        "type"          => "box",
        "layout"        => "horizontal",
        "spacing"       => "md",
        "paddingTop"    => i.zero? ? "md" : "lg",
        "paddingBottom" => "lg",
        "alignItems"    => "center",
        "action"        => {
          "type"        => "postback",
          "label"       => label,
          "data"        => URI.encode_www_form([
            [ "answer", label ],
            [ "question_number", question_number ],
            [ "correct", correct ]
          ]),
          "displayText" => label
        },
        "contents" => [
          {
            "type"            => "box",
            "layout"          => "vertical",
            "width"           => "26px",
            "height"          => "26px",
            "cornerRadius"    => "6px",
            "backgroundColor" => BADGE_BG_COLOR,
            "justifyContent"  => "center",
            "alignItems"      => "center",
            "contents"        => [
              {
                "type"   => "text",
                "text"   => label,
                "size"   => "sm",
                "color"  => BADGE_TEXT_COLOR,
                "weight" => "bold",
                "align"  => "center"
              }
            ]
          },
          {
            "type"    => "text",
            "text"    => text.to_s,
            "size"    => "sm",
            "wrap"   => true,
            "color"   => "#333333",
            "flex"    => 1,
            "gravity" => "center"
          }
        ]
      }
      rows << { "type" => "separator", "color" => "#EEEEEE" } unless i == choices.size - 1
    end

    {
      "type"     => "flex",
      "altText"  => "問#{question_number} の問題です",
      "contents" => {
        "type" => "bubble",
        "body" => {
          "type"       => "box",
          "layout"     => "vertical",
          "paddingAll" => "16px",
          "contents"   => [
            {
              "type"  => "text",
              "text"  => question_text,
              "wrap"  => true,
              "size"  => "sm",
              "color" => "#333333"
            },
            {
              "type"   => "text",
              "text"   => source_text,
              "size"   => "xs",
              "color"  => "#999999",
              "margin" => "lg"
            },
            { "type" => "separator", "margin" => "lg" }
          ] + rows
        }
      }
    }
  end

  def self.result(is_correct:, correct:, question_id:, explanation_url: nil, character_image_url: nil)
    icon_span  = is_correct ? { "text" => "⭕ ", "color" => "#2EBD59" } : { "text" => "❌ ", "color" => "#FF4D4F" }
    label_span = is_correct ? { "text" => "正解！ 答えは " } : { "text" => "不正解… 正解は " }

    result_contents = [
      {
        "type"     => "text",
        "wrap"     => true,
        "size"     => "md",
        "color"    => "#333333",
        "contents" => [
          icon_span.merge("type" => "span"),
          label_span.merge("type" => "span"),
          { "type" => "span", "text" => correct, "color" => BADGE_TEXT_COLOR, "weight" => "bold" },
          { "type" => "span", "text" => is_correct ? " でした！" : " でした" }
        ]
      }
    ]

    body_contents = []

    if character_image_url
      body_contents << {
        "type"        => "image",
        "url"         => character_image_url,
        "size"        => "sm",
        "aspectMode"  => "fit",
        "aspectRatio" => "1:1",
        "align"       => "center"
      }
    end

    body_contents << {
      "type"       => "box",
      "layout"     => "vertical",
      "paddingAll" => "16px",
      "contents"   => result_contents
    }

    {
      "type"     => "flex",
      "altText"  => is_correct ? "正解！" : "不正解...",
      "contents" => {
        "type" => "bubble",
        "body" => {
          "type"     => "box",
          "layout"   => "vertical",
          "spacing"  => "md",
          "contents" => body_contents
        },
        "footer" => {
          "type"     => "box",
          "layout"   => "vertical",
          "spacing"  => "sm",
          "contents" => [
            {
              "type"            => "box",
              "layout"          => "horizontal",
              "paddingAll"      => "12px",
              "cornerRadius"    => "lg",
              "backgroundColor" => PRIMARY_COLOR,
              "justifyContent"  => "center",
              "spacing"         => "sm",
              "action"          => {
                "type"  => "uri",
                "label" => "解説を見る",
                "uri"   => explanation_url || "https://www.fe-siken.com/fe/"
              },
              "contents" => [
                { "type" => "text", "text" => "📖", "color" => "#FFFFFF", "flex" => 0 },
                { "type" => "text", "text" => "解説を見る", "color" => "#FFFFFF", "weight" => "bold", "align" => "center", "size" => "md" }
              ]
            },
            {
              "type"            => "box",
              "layout"          => "horizontal",
              "paddingAll"      => "12px",
              "cornerRadius"    => "lg",
              "backgroundColor" => "#FFFFFF",
              "borderWidth"     => "1px",
              "borderColor"     => BORDER_COLOR,
              "justifyContent"  => "center",
              "alignItems"      => "center",
              "action"          => {
                "type"        => "postback",
                "label"       => "次の問題へ",
                "data"        => "action=next",
                "displayText" => "次の問題へ"
              },
              "contents" => [
                { "type" => "text", "text" => "次の問題へ", "color" => "#333333", "weight" => "bold", "size" => "md", "align" => "center", "flex" => 1 },
                { "type" => "text", "text" => "›", "color" => PRIMARY_COLOR, "weight" => "bold", "size" => "lg", "flex" => 0 }
              ]
            },
            {
              "type"            => "box",
              "layout"          => "horizontal",
              "paddingAll"      => "12px",
              "cornerRadius"    => "lg",
              "backgroundColor" => GRAY_BG,
              "justifyContent"  => "center",
              "spacing"         => "sm",
              "action"          => {
                "type"        => "postback",
                "label"       => "終了する",
                "data"        => "action=end",
                "displayText" => "終了する"
              },
              "contents" => [
                { "type" => "text", "text" => "⏹", "color" => "#777777", "flex" => 0 },
                { "type" => "text", "text" => "終了する", "color" => "#777777", "weight" => "bold", "align" => "center", "size" => "md" }
              ]
            }
          ]
        }
      }
    }
  end
end
