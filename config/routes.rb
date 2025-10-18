Rails.application.routes.draw do
  root to: redirect("/api/v1/health")

  # API v1 routes
  namespace :api do
    namespace :v1 do
      # Health check endpoint
      resource :health, only: [ :show ], controller: "health"

      # Customers resource
      resources :customers, only: [ :index, :show, :create, :update, :destroy ]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
