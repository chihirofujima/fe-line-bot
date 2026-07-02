require 'rails_helper'

RSpec.describe DeliverQuestionJob, type: :job do
  let(:user)     { create(:user) }
  let(:setting)  { create(:delivery_setting, user: user) }
  let(:question) { create(:question) }

  # LINE API呼び出しは全テストでスタブ化
  before do
    allow_any_instance_of(Line::Bot::V2::MessagingApi::ApiClient)
      .to receive(:push_message)
  end

  describe "#perform" do
    context "ユーザーが存在しない場合" do
      it "何もせずreturnする" do
        expect { described_class.perform_now(0) }.not_to raise_error
      end
    end

    context "配信設定がない場合" do
      it "何もせずreturnする" do
        expect { described_class.perform_now(user.id) }.not_to raise_error
      end
    end

    context "問題が1件も存在しない場合" do
      before { setting }
      it "何もせずreturnする" do
        expect { described_class.perform_now(user.id) }.not_to raise_error
      end
    end

    context "正常系（ユーザー・設定・問題が揃っている場合）" do
      before { setting; question }

      it "LINE APIにpush_messageが送信される" do
        api = instance_double(Line::Bot::V2::MessagingApi::ApiClient)
        allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(api)
        expect(api).to receive(:push_message)
        described_class.perform_now(user.id)
      end

      it "次回配信ジョブがエンキューされる" do
        expect {
          described_class.perform_now(user.id)
        }.to have_enqueued_job(DeliverQuestionJob)
      end
    end

    context "DeliveryTimeCalculatorがnilを返す場合" do
      before { setting; question }

      it "次回ジョブがエンキューされない" do
        allow(DeliveryTimeCalculator).to receive(:call).and_return(nil)
        expect {
          described_class.perform_now(user.id)
        }.not_to have_enqueued_job(DeliverQuestionJob)
      end
    end
  end

  describe "#select_question（間接テスト）" do
    before { setting }

    context "rand < 0.7（復習ターン）かつ復習問題がある場合" do
      it "due_for_reviewな問題が選ばれる" do
        allow_any_instance_of(described_class).to receive(:rand).and_return(0.5)
        review_answer = FactoryBot.create(:answer,
          user: user, question: question, next_review_at: 1.day.ago)
        # send_questionに渡されるquestionがreview_answerのquestionであることを確認
        expect_any_instance_of(described_class)
          .to receive(:send_question).with(user, question)
        described_class.perform_now(user.id)
      end
    end

    context "rand < 0.7（復習ターン）かつ復習問題がない場合" do
      before { question }
    
      it "未回答の新問題が選ばれる" do
        allow_any_instance_of(described_class).to receive(:rand).and_return(0.5)
        expect_any_instance_of(described_class)
          .to receive(:send_question).with(user, question)
        described_class.perform_now(user.id)
      end
    end

    context "rand >= 0.7（新問題ターン）の場合" do
      before { question }

      it "復習をスキップして新問題が選ばれる" do
        job = described_class.new(user.id)
        allow(job).to receive(:rand).and_return(0.8)
        expect(Answer).not_to receive(:due_for_review)
        expect(job).to receive(:send_question).with(user, question)
        job.perform_now
      end
    end

    context "全問題を回答済みの場合" do
      it "既回答問題からランダムに選ばれる（nilにならない）" do
        FactoryBot.create(:answer, user: user, question: question)
        allow_any_instance_of(described_class).to receive(:rand).and_return(0.8)
        expect_any_instance_of(described_class)
          .to receive(:send_question).with(user, question)
        described_class.perform_now(user.id)
      end
    end

    context "LINE API送信が失敗する場合" do
      before do
       setting
       question
       allow_any_instance_of(Line::Bot::V2::MessagingApi::ApiClient)
        .to receive(:push_message).and_raise(StandardError, "API Error")
      end

      it "エラーがraiseされず処理が継続する" do
        expect{ described_class.perform_now(user.id)}.not_to raise_error
      end

      it "送信失敗しても次回ジョブはスケジュールされる" do
        expect {
          described_class.perform_now(user.id)
        }.to have_enqueued_job(DeliverQuestionJob)
      end
    end
  end
end