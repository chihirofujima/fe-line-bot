require "uri"

module FlexBuilder
  def self.question(question_id:, question_text:, choices:, correct:)
    rows = choices.map do |label, text|
      {
        "type"     => "box",
        "layout"   => "horizontal",
        "margin"   => "md",
        "action"   => {
          "type"        => "postback",
          "label"       => label,
          "data"        => URI.encode_www_form([
            [ "answer", label ],
            [ "question_id", question_id ],
            [ "correct", correct ]
          ]),
          "displayText" => label
        },
        "contents" => [
          {
            "type"  => "text",
            "text"  => label,
            "size"  => "sm",
            "color" => "#555555",
            "flex"  => 1
          },
          {
            "type"  => "text",
            "text"  => text.to_s,
            "size"  => "sm",
            "color" => "#111111",
            "flex"  => 5,
            "wrap"  => true
          }
        ]
      }
    end

    {
      "type"     => "flex",
      "altText"  => "問#{question_id} の問題です",
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
            { "type" => "separator", "margin" => "md" }
          ] + rows
        }
      }
    }
  end

  def self.result(is_correct:, correct:, question_id:, explanation_url: nil)
    result_text = is_correct \
      ? "⭕ 正解！ 正解は #{correct} です"
      : "❌ 不正解... 正解は #{correct} でした"

    {
      "type"     => "flex",
      "altText"  => is_correct ? "正解！" : "不正解...",
      "contents" => {
        "type" => "bubble",
        "body" => {
          "type"       => "box",
          "layout"     => "vertical",
          "spacing"    => "md",
          "contents"   => [
            {
              "type"       => "box",
              "layout"     => "vertical",
              "paddingAll" => "16px",
              "contents"   => [
                {
                  "type"  => "text",
                  "text"  => result_text,
                  "wrap"  => true,
                  "size"  => "md",
                  "color" => "#333333"
                }
              ]
            }
          ]
        },
        "footer" => {
          "type"     => "box",
          "layout"   => "vertical",
          "spacing"  => "sm",
          "contents" => [
            {
              "type"   => "button",
              "style"  => "primary",
              "height" => "sm",
              "action" => {
                "type"  => "uri",
                "label" => "解説を見る",
                "uri"   => explanation_url || "https://www.fe-siken.com/fe/"
              }
            },
            {
              "type"   => "button",
              "style"  => "secondary",
              "height" => "sm",
              "action" => {
                "type"        => "postback",
                "label"       => "次の問題へ",
                "data"        => "action=next",
                "displayText" => "次の問題へ"
              }
            },
            {
              "type"   => "button",
              "style"  => "secondary",
              "height" => "sm",
              "color"  => "#aaaaaa",
              "action" => {
                "type"        => "postback",
                "label"       => "終了する",
                "data"        => "action=end",
                "displayText" => "終了する"
              }
            }
          ]
        }
      }
    }
  end
end
