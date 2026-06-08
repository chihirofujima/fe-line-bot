require 'rails_helper'

RSpec.describe "Liff::Histories", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/liff/history/index"
      expect(response).to have_http_status(:success)
    end
  end

end
