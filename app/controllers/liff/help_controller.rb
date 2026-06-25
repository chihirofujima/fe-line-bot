module Liff
  class HelpController < ApplicationController
    layout "public"

    def index
      @liff_settings_url = "https://liff.line.me/#{ENV['LIFF_ID_SETTINGS']}"
    end
  end
end