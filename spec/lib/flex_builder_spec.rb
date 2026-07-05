require "rails_helper"

RSpec.describe FlexBuilder do
  describe ".question" do
    let(:choices) do
      {
        "ア" => "選択肢Aのテキスト",
        "イ" => "選択肢Bのテキスト",
        "ウ" => "選択肢Cのテキスト",
        "エ" => "選択肢Dのテキスト"
      }
    end

    let(:flex_message) do
      described_class.question(
        question_number: 5,
        question_text: "次のうち、正しいものはどれか。",
        choices: choices,
        correct: "イ",
        year: 2023,
        subject: "科目A"
      )
    end

    let(:bubble) { flex_message["contents"] }
    let(:body)   { bubble["body"] }

    it "type が flex になっている" do
      expect(flex_message["type"]).to eq("flex")
    end

    it "altText に問題番号が含まれる" do
      expect(flex_message["altText"]).to eq("問5 の問題です")
    end

    it "bubble の type が bubble になっている" do
      expect(bubble["type"]).to eq("bubble")
    end

    it "問題文がそのまま本文に含まれる" do
      question_text_node = body["contents"].find { |c| c["text"] == "次のうち、正しいものはどれか。" }
      expect(question_text_node).to be_present
      expect(question_text_node["wrap"]).to eq(true)
    end

    describe "出典表記(source_text)" do
      context "yearが2019年以下の場合" do
        let(:flex_message) do
          described_class.question(
            question_number: 1,
            question_text: "text",
            choices: choices,
            correct: "ア",
            year: 2019
          )
        end

        it "「秋期」が含まれる" do
          source_node = body["contents"].find { |c| c["text"]&.start_with?("出典") }
          expect(source_node["text"]).to eq("出典：IPA FE試験 2019年 秋期 科目A 問1")
        end
      end

      context "yearが2020年以降の場合" do
        it "期の表記が含まれない" do
          source_node = body["contents"].find { |c| c["text"]&.start_with?("出典") }
          expect(source_node["text"]).to eq("出典：IPA FE試験 2023年 科目A 問5")
        end
      end

      context "subjectを指定しない場合" do
        let(:flex_message) do
          described_class.question(
            question_number: 1,
            question_text: "text",
            choices: choices,
            correct: "ア",
            year: 2023
          )
        end

        it "デフォルトの「科目A」が使われる" do
          source_node = body["contents"].find { |c| c["text"]&.start_with?("出典") }
          expect(source_node["text"]).to include("科目A")
        end
      end
    end

    describe "選択肢の描画" do
      # 本文contentsの先頭3要素(問題文・出典・separator)を除いた残りが選択肢行
      let(:choice_rows) { body["contents"][3..] }

      it "選択肢の数だけpostbackアクション付きの行が生成される" do
        action_rows = choice_rows.select { |c| c["type"] == "box" && c["layout"] == "horizontal" }
        expect(action_rows.size).to eq(choices.size)
      end

      it "各行のpostbackにanswer・question_number・correctが含まれる" do
        action_rows = choice_rows.select { |c| c["type"] == "box" && c["layout"] == "horizontal" }
        first_action = action_rows.first["action"]

        expect(first_action["type"]).to eq("postback")
        parsed_data = Rack::Utils.parse_nested_query(first_action["data"])
        expect(parsed_data["answer"]).to eq("ア")
        expect(parsed_data["question_number"]).to eq("5")
        expect(parsed_data["correct"]).to eq("イ")
      end

      it "displayTextにも選択肢ラベルが表示される" do
        action_rows = choice_rows.select { |c| c["type"] == "box" && c["layout"] == "horizontal" }
        expect(action_rows.first["action"]["displayText"]).to eq("ア")
      end

      it "選択肢間にseparatorが挿入され、最後の選択肢の後には挿入されない" do
        separators = choice_rows.select { |c| c["type"] == "separator" }
        # 選択肢が4つなら、間に入るseparatorは3つ
        expect(separators.size).to eq(choices.size - 1)
      end

      it "バッジ部分に選択肢ラベルが表示される" do
        action_rows = choice_rows.select { |c| c["type"] == "box" && c["layout"] == "horizontal" }
        badge_box = action_rows.first["contents"].first
        badge_text = badge_box["contents"].first

        expect(badge_text["text"]).to eq("ア")
        expect(badge_text["color"]).to eq(FlexBuilder::BADGE_TEXT_COLOR)
      end

      it "選択肢本文が表示される" do
        action_rows = choice_rows.select { |c| c["type"] == "box" && c["layout"] == "horizontal" }
        text_box = action_rows.first["contents"].last

        expect(text_box["text"]).to eq("選択肢Aのテキスト")
        expect(text_box["wrap"]).to eq(true)
      end
    end
  end

  describe ".result" do
    context "正解の場合" do
      let(:flex_message) do
        described_class.result(
          is_correct: true,
          correct: "イ",
          question_id: 5,
          explanation_url: "https://example.com/explanation"
        )
      end

      let(:body_contents) { flex_message["contents"]["body"]["contents"] }
      let(:result_text_node) { body_contents.last["contents"].first }

      it "altTextが「正解！」になる" do
        expect(flex_message["altText"]).to eq("正解！")
      end

      it "⭕アイコンと緑色が使われる" do
        icon_span = result_text_node["contents"].first
        expect(icon_span["text"]).to eq("⭕ ")
        expect(icon_span["color"]).to eq("#2EBD59")
      end

      it "正解のラベルと正解の選択肢が表示される" do
        spans = result_text_node["contents"]
        expect(spans[1]["text"]).to eq("正解！ 答えは ")
        expect(spans[2]["text"]).to eq("イ")
        expect(spans[2]["color"]).to eq(FlexBuilder::BADGE_TEXT_COLOR)
        expect(spans[3]["text"]).to eq(" でした！")
      end

      it "character_image_urlを指定しない場合は画像が含まれない" do
        expect(body_contents.none? { |c| c["type"] == "image" }).to eq(true)
      end
    end

    context "不正解の場合" do
      let(:flex_message) do
        described_class.result(
          is_correct: false,
          correct: "ウ",
          question_id: 5
        )
      end

      let(:body_contents) { flex_message["contents"]["body"]["contents"] }
      let(:result_text_node) { body_contents.last["contents"].first }

      it "altTextが「不正解...」になる" do
        expect(flex_message["altText"]).to eq("不正解...")
      end

      it "❌アイコンと赤色が使われる" do
        icon_span = result_text_node["contents"].first
        expect(icon_span["text"]).to eq("❌ ")
        expect(icon_span["color"]).to eq("#FF4D4F")
      end

      it "不正解のラベルと正解の選択肢が表示される" do
        spans = result_text_node["contents"]
        expect(spans[1]["text"]).to eq("不正解… 正解は ")
        expect(spans[2]["text"]).to eq("ウ")
        expect(spans[3]["text"]).to eq(" でした")
      end

      it "explanation_urlを省略した場合はデフォルトURLが使われる" do
        buttons = flex_message["contents"]["footer"]["contents"]
        explanation_button = buttons.first
        expect(explanation_button["action"]["uri"]).to eq("https://www.fe-siken.com/fe/")
      end
    end

    context "character_image_urlを指定した場合" do
      let(:flex_message) do
        described_class.result(
          is_correct: true,
          correct: "ア",
          question_id: 1,
          character_image_url: "https://example.com/character.png"
        )
      end

      it "本文の先頭にキャラクター画像が挿入される" do
        body_contents = flex_message["contents"]["body"]["contents"]
        image_node = body_contents.first

        expect(image_node["type"]).to eq("image")
        expect(image_node["url"]).to eq("https://example.com/character.png")
        expect(image_node["aspectRatio"]).to eq("1:1")
      end
    end

    describe "フッターのボタン" do
      let(:flex_message) do
        described_class.result(
          is_correct: true,
          correct: "ア",
          question_id: 1,
          explanation_url: "https://example.com/exp"
        )
      end

      let(:buttons) { flex_message["contents"]["footer"]["contents"] }

      it "3つのボタン(解説を見る・次の問題へ・終了する)が存在する" do
        expect(buttons.size).to eq(3)
      end

      it "「解説を見る」ボタンはuriアクションで指定したexplanation_urlに遷移する" do
        button = buttons[0]
        expect(button["action"]["type"]).to eq("uri")
        expect(button["action"]["label"]).to eq("解説を見る")
        expect(button["action"]["uri"]).to eq("https://example.com/exp")
      end

      it "「次の問題へ」ボタンはpostbackでaction=nextを送る" do
        button = buttons[1]
        expect(button["action"]["type"]).to eq("postback")
        expect(button["action"]["data"]).to eq("action=next")
        expect(button["action"]["displayText"]).to eq("次の問題へ")
      end

      it "「終了する」ボタンはpostbackでaction=endを送る" do
        button = buttons[2]
        expect(button["action"]["type"]).to eq("postback")
        expect(button["action"]["data"]).to eq("action=end")
        expect(button["action"]["displayText"]).to eq("終了する")
      end
    end
  end
end
