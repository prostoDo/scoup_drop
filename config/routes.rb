Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :auth do
      post :login, to: "/api/auth#login"
      post :logout, to: "/api/auth#logout"
      get :me, to: "/api/auth#me"
    end

    post :sync, to: "sync#create"
    resources :sprints, only: %i[index show]
  end

  root "spa#index"
  get "*path", to: "spa#index", constraints: lambda { |request|
    !request.path.start_with?("/api/", "/up", "/app/")
  }
end
