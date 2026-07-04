FactoryBot.define do
  factory :share_token do
    association :user

    # token と expires_at はモデルの before_validation コールバックで
    # 自動生成されるため、ここでは指定しない
  end
end
