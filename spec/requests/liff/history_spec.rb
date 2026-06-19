require 'rails_helper'

RSpec.describe "Liff::History", type: :request do
  let(:user) { User.create!(line_user_id: "U1234567890", name: "テストユーザー") }

  describe "POST /liff/history/share_tokens" do
    before do
      allow_any_instance_of(Liff::HistoryController).to receive(:set_user) do |controller|
        controller.instance_variable_set(:@user, user)
      end
    end

    it "share_tokenが新規作成される" do
      expect {
        post "/liff/history/share_tokens"
      }.to change(ShareToken, :count).by(1)
    end

    it "正答率・学習日数・定着率・総回答数がsnapshot_dataに保存される" do
      question = Question.create!(content: "テスト問題", correct_answer: "1")
      Answer.create!(user: user, question: question, is_correct: true)

      post "/liff/history/share_tokens"

      share_token = ShareToken.last
      expect(share_token.snapshot_data).to include(
        "accuracy_rate", "total_study_days", "mastery_rate", "total_answers"
      )
    end

    it "share_urlがレスポンスに含まれる" do
      post "/liff/history/share_tokens"

      json = JSON.parse(response.body)
      expect(json["share_url"]).to include("/share/")
    end
  end
end
