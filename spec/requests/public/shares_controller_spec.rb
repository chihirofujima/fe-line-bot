require "rails_helper"

RSpec.describe "Public::Shares", type: :request do
  describe "GET /share/:token" do
    context "有効なトークンの場合" do
      let(:share_token) { create(:share_token) }

      it "200を返す" do
        get "/share/#{share_token.token}"
        expect(response).to have_http_status(:ok)
      end
    end

    context "存在しないトークンの場合" do
      it "404を返す" do
        get "/share/invalid-token"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "期限切れトークンの場合" do
      let(:share_token) { create(:share_token, expires_at: 1.day.ago) }

      it "410を返す" do
        get "/share/#{share_token.token}"
        expect(response).to have_http_status(:gone)
      end
    end
  end

  describe "GET /share/:token/og_image" do
    context "有効なトークンの場合" do
      let(:share_token) { create(:share_token) }

      it "200かつimage/pngを返す" do
        get "/share/#{share_token.token}/og_image"
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("image/png")
      end
    end

    context "存在しないトークンの場合" do
      it "404を返す" do
        get "/share/invalid-token/og_image"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "期限切れトークンの場合" do
      let(:share_token) { create(:share_token, expires_at: 1.day.ago) }

      it "410を返す" do
        get "/share/#{share_token.token}/og_image"
        expect(response).to have_http_status(:gone)
      end
    end
  end
end
