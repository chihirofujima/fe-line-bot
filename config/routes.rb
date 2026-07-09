require "mission_control/jobs/engine"

Rails.application.routes.draw do
  get "landing/index"
  post "/line/callback" => "line_bot#callback"

  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "share/:token", to: "public/shares#show", as: :public_share
  get "share/:token/og_image", to: "public/shares#og_image", as: :public_share_og_image

  get "/terms", to: "public/pages#terms", as: :terms
  get "/privacy", to: "public/pages#privacy", as: :privacy

  mount MissionControl::Jobs::Engine, at: "/jobs"

  namespace :liff do
    post "session", to: "sessions#create"

    get "settings", to: "settings#index"
    get "settings/current", to: "settings#current"
    get "history",  to: "history#index"
    get "history/data", to: "history#data"
    post "history/share_tokens", to: "history#create_share_token"
    get "help", to: "help#index"
    patch "settings", to: "settings#update"
  end

  root to: "landing#index"
end
