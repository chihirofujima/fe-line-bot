require 'rails_helper'
 
RSpec.describe ShareToken, type: :model do
  describe 'アソシエーション' do
    it 'Userに属している' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq :belongs_to
    end
  end
 
  describe '#generate_token（before_validationコールバック）' do
    it '新規作成時にtokenが自動生成される' do
      share_token = build(:share_token, token: nil)
 
      expect { share_token.valid? }.to change { share_token.token }.from(nil)
    end
 
    it '生成されるtokenはurlsafe_base64形式の文字列である' do
      share_token = create(:share_token)
 
      expect(share_token.token).to match(%r{\A[A-Za-z0-9\-_]+\z})
    end
 
    it 'すでにtokenが設定されている場合は上書きしない' do
      share_token = build(:share_token, token: 'already_set_token')
 
      share_token.valid?
 
      expect(share_token.token).to eq('already_set_token')
    end
  end
 
  describe '#set_expiration（before_validationコールバック）' do
    it '新規作成時にexpires_atが30日後に設定される' do
      travel_to Time.zone.local(2026, 1, 1, 12, 0, 0) do
        share_token = create(:share_token)
 
        expect(share_token.expires_at).to eq(30.days.from_now)
      end
    end
 
    it 'すでにexpires_atが設定されている場合は上書きしない' do
      custom_time = 10.days.from_now
      share_token = build(:share_token, expires_at: custom_time)
 
      share_token.valid?
 
      expect(share_token.expires_at).to be_within(1.second).of(custom_time)
    end
  end
 
  describe 'バリデーション' do
    # generate_token コールバックが token を自動で埋めてしまうため、
    # presence / uniqueness の単体挙動を確認したい場合はコールバックをスタブして
    # 意図的に token を nil や重複値のままにする必要がある。
    describe 'token の presence' do
      it 'tokenが空だと無効になる' do
        share_token = build(:share_token)
        allow(share_token).to receive(:generate_token) # コールバックによる自動生成を止める
        share_token.token = nil
 
        expect(share_token).not_to be_valid
        expect(share_token.errors[:token]).to include('を入力してください')
      end
    end
 
    describe 'token の uniqueness' do
      it '既存のtokenと重複していると無効になる' do
        existing = create(:share_token)
 
        share_token = build(:share_token, user: existing.user)
        allow(share_token).to receive(:generate_token) # コールバックによる自動生成を止める
        share_token.token = existing.token
 
        expect(share_token).not_to be_valid
        expect(share_token.errors[:token]).to include('はすでに存在します')
      end
    end
  end
 
  describe '#expired?' do
    context '有効期限を過ぎている場合' do
      it 'trueを返す' do
        share_token = build(:share_token, expires_at: 1.day.ago)
 
        expect(share_token.expired?).to be true
      end
    end
 
    context '有効期限内の場合' do
      it 'falseを返す' do
        share_token = build(:share_token, expires_at: 1.day.from_now)
 
        expect(share_token.expired?).to be false
      end
    end
 
    context '有効期限とちょうど同時刻の場合（境界値）' do
      it 'falseを返す（< 判定のため、ちょうど同時刻は期限切れ扱いにならない）' do
        travel_to Time.zone.local(2026, 1, 1, 12, 0, 0) do
          share_token = build(:share_token, expires_at: Time.current)
 
          expect(share_token.expired?).to be false
        end
      end
    end
  end
end