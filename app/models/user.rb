# app/models/user.rb
class User < ApplicationRecord
  # LINEユーザーIDでの検索・作成に使うバリデーション
  validates :line_user_id, presence: true, uniqueness: true

  # 状態の定義（enum を使うと管理しやすい）
  enum state: {
    idle: 0,           # 待機中
    waiting_answer: 1  # 回答待ち（出題済み）
  }

  # 出題中の問題との紐付け（Questionモデルがある場合）
  belongs_to :current_question, class_name: 'Question', optional: true
end