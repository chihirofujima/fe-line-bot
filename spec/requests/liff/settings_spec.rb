require 'rails_helper'

RSpec.describe "Liff::Settings", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/liff/settings/index"
      expect(response).to have_http_status(:success)
    end
  end

end
