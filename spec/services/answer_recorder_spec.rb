require 'rails_helper'

RSpec.describe AnswerRecorder do
  describe '.call' do
    let(:user){ create(:user) }
    let(:question){ create(:question) }  

    subject(:call_recorder) do
      described_class.call(
        user: user,
        question: question,
        answer_choice: answer_choice,
        is_correct: is_correct
      )
    end

    context '初めてその問題に回答する場合' do
      let(:answer_choice){ 1 }
      let(:is_correct){ true }

      it '新しいAnswerレコードが1件作成される' do
        expect { call_recorder }.to change(Answer, :count).by(1)
      end

      it '渡した属性が正しく保存される' do
        answer = call_recorder
        expect(answer).to have_attributes(
          user_id: user.id,
          question_id: question.id,
          answer_choice: 1, 
          is_correct: true
        )
      end

      it 'delivered_atに現在時刻が設定される' do
        freeze_time do
          answer = call_recorder
          expect(answer.delivered_at).to eq(Time.current)
        end
      end
    end

    context 'すでに回答したことがある問題に再回答する場合' do
      let(:answer_choice){ 2 }
      let(:is_correct) { false }
      let!(:existing_answer) do
        create(
          :answer,
          user: user,
          question: question,
          answer_choice: 1,
          is_correct: true,
          delivered_at: 3.days.ago,
          last_answered_at: 3.days.ago
        )
      end

      it '新しいレコードは作られず、既存レコードが更新される' do
        expect { call_recorder }.not_to change(Answer, :count)
      end

      it 'answer_choiceとis_correctが最新の回答内容で上書きされる' do
        answer = call_recorder
        expect(answer).to have_attributes(answer_choice: 2, is_correct: false)
      end

      it 'delivered_atは最初に配信された時刻のまま変わらない' do
        answer = call_recorder
        expect(answer.delivered_at).to be_within(1.second).of(3.days.ago)
      end

      it 'last_answered_atは現在時刻に更新される' do
        freeze_time do
          answer = call_recorder
          expect(answer.last_answered_at).to eq(Time.current)
        end
      end
      
      it '同じレコード(id)が使い回される' do
        answer = call_recorder
        expect(answer.id).to eq(existing_answer.id)
      end
    end

    context '正解した場合' do
      let(:answer_choice) { 1 }
      let(:is_correct) { true }
 
      it 'is_correctがtrueで保存される' do
        expect(call_recorder.is_correct).to eq(true)
      end
    end

    context '不正解だった場合' do
      let(:answer_choice) { 3 }
      let(:is_correct) { false }
 
      it 'is_correctがfalseで保存される' do
        expect(call_recorder.is_correct).to eq(false)
      end
    end

    context '戻り値について' do
      let(:answer_choice) { 1 }
      let(:is_correct) { true }
 
      it '保存されたAnswerのインスタンスを返す' do
        expect(call_recorder).to be_a(Answer)
      end
 
      it '返されたAnswerは永続化済み(persisted)である' do
        expect(call_recorder).to be_persisted
      end
    end
  end
end