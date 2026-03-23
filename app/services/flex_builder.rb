module FlexBuilder
  def self.question(question_id:, year:, question_text:, choices:, correct:)
    choice_texts = choices.map do |label, text|
      { type: "text", text: "#{label}  #{text}", wrap: true, size: "sm", color: "#333333" }
    end

    buttons = choices.keys.map do |label|
      {
        type:   "button",
        action: {
          type:        "postback",
          label:       label,
          data:        "answer=#{label}&question_id=#{question_id}&year=#{year}&correct=#{correct}",
          displayText: label
        },
        style:  "secondary",
        height: "sm",
        flex:   1
      }
    end

    {
      type:     "flex",
      altText:  "問#{question_id} の問題です",
      contents: {
        type: "bubble",
        body: {
          type: "box", layout: "vertical", spacing: "none", paddingAll: "0px",
          contents: [
            { type: "text", text: question_text, wrap: true, size: "md", color: "#333333", paddingAll: "16px" },
            { type: "separator" },
            { type: "box", layout: "vertical", paddingAll: "16px", spacing: "sm", contents: choice_texts },
            { type: "separator" }
          ]
        },
        footer: {
          type: "box", layout: "horizontal", spacing: "sm", paddingAll: "12px",
          contents: buttons
        }
      }
    }
  end

  def self.result(is_correct:, correct:, question_id:, explanation_url: nil)
    result_text = is_correct \
      ? "✅ 正解！ 正解は #{correct} です"
      : "❌ 不正解... 正解は #{correct} でした"

    {
      type:     "flex",
      altText:  is_correct ? "正解！" : "不正解...",
      contents: {
        type: "bubble",
        body: {
          type: "box", layout: "vertical", spacing: "none", paddingAll: "0px",
          contents: [
            { type: "text", text: result_text, wrap: true, size: "md", color: "#333333", paddingAll: "16px" },
            { type: "separator" },
            { type: "button", action: { type: "uri", label: "解説リンク", uri: explanation_url || "https://example.com" }, style: "link", height: "sm" },
            { type: "separator" },
            { type: "button", action: { type: "postback", label: "次の問題へ", data: "action=next", displayText: "次の問題へ" }, style: "link", height: "sm" },
            { type: "separator" },
            { type: "button", action: { type: "postback", label: "終了する", data: "action=end", displayText: "終了する" }, style: "link", height: "sm", color: "#aaaaaa" }
          ]
        }
      }
    }
  end
end
