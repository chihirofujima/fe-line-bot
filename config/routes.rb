require "mission_control/jobs/engine"

Rails.application.routes.draw do
  post "/line/callback" => "line_bot#callback"

  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  mount MissionControl::Jobs::Engine, at: "/jobs"

  namespace :api do
    post "quiz/deliver", to: "quiz#deliver"
  end

  namespace :liff do
    get "settings", to: "settings#index"
    get "settings/current", to: "settings#current"
    get "history",  to: "history#index"
    get "help", to: "help#index"
    patch "settings", to: "settings#update"
  end

  root to: proc { [ 200, {}, [ "OK" ] ] }
end
