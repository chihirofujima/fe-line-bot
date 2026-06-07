require 'rails_helper'

RSpec.describe Answer, type: :model do
  # テストデータの準備
  let(:user) { User.create!(line_user_id: "U1234567890", name: "テストユーザー") }
  let(:question) { Question.create!(content: "テスト問題", correct_answer: "1") }

  describe 'アソシエーション' do
    it 'userに属していること' do
      answer = Answer.new(user: user, question: question)
      expect(answer.user).to eq(user)
    end

    it 'questionに属していること' do
      answer = Answer.new(user: user, question: question)
      expect(answer.question).to eq(question)
    end
  end

  describe 'スコープ' do
    describe '.due_for_review' do
      let!(:answer_past) { Answer.create(user: user, question: question, next_review_at: 1.day.ago) }
      let!(:answer_today) { Answer.create(user: user, question: question, next_review_at: Time.current) }
      let!(:answer_future) { Answer.create(user: user, question: question, next_review_at: 1.day.from_now) }
      let!(:answer_nil) { Answer.create(user: user, question: question, next_review_at: nil) }

      it '今日以前のレビュー予定のものを取得すること' do
        results = Answer.due_for_review
        expect(results).to include(answer_past, answer_today, answer_nil)
        expect(results).not_to include(answer_future)
      end
    end

    describe '.by_next_review' do
      let!(:answer1) { Answer.create(user: user, question: question, next_review_at: 3.days.from_now) }
      let!(:answer2) { Answer.create(user: user, question: question, next_review_at: 1.day.from_now) }
      let!(:answer3) { Answer.create(user: user, question: question, next_review_at: 2.days.from_now) }

      it 'next_review_atの昇順で取得すること' do
        results = Answer.where(id: [ answer1.id, answer2.id, answer3.id ]).by_next_review
        expect(results).to eq([ answer2, answer3, answer1 ])
      end
    end
  end

  describe '#needs_review?' do
    it 'next_review_atがnilのときtrueを返すこと' do
      answer = Answer.new(next_review_at: nil)
      expect(answer.needs_review?).to be true
    end

    it '過去の日時のときtrueを返すこと' do
      answer = Answer.new(next_review_at: 1.day.ago)
      expect(answer.needs_review?).to be true
    end

    it '未来の日時のときfalseを返すこと' do
      answer = Answer.new(next_review_at: 1.day.from_now)
      expect(answer.needs_review?).to be false
    end
  end

  describe '#apply_review!' do
    it 'SpacedRepetitionServiceを呼び出してsave!すること' do
      answer = Answer.create!(user: user, question: question)
      service_double = instance_double(SpacedRepetitionService)

      allow(SpacedRepetitionService).to receive(:new).with(answer).and_return(service_double)
      allow(service_double).to receive(:calculate_next_review).with(4)
      expect(answer).to receive(:save!)

      answer.apply_review!(4)
    end
  end
end
