Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount ActionCable.server => "/cable"

  # Auth (top-level, fuera del namespace para usar AuthController directamente)
  post "/api/v1/auth/google", to: "auth#google"

  # Dev tools (solo disponible en development)
  if Rails.env.development?
    namespace :dev do
      patch "switch_role", to: "role_switcher#switch_role"
      post  "switch_user", to: "role_switcher#switch_user"
    end
  end

  namespace :api do
    namespace :v1 do
      # Público — sin auth
      get "store_status", to: "store_status#show"

      # Session
      delete "/session", to: "sessions#destroy"

      # Usuario autenticado
      get "/me", to: "users#me"

      # Menú (público - sin auth para GET)
      resources :categories, only: %i[index create update destroy]
      resources :menu_items, only: %i[create update destroy]

      # Órdenes
      resources :orders, only: %i[index show create] do
        collection do
          post :counter, to: "orders#create_counter"
        end
        member do
          patch :confirm_payment
          patch :status, to: "orders#update_status"
          patch :cancel
        end
      end

      # Repartos
      resources :delivery_assignments, only: %i[index create] do
        member do
          patch :status, to: "delivery_assignments#update_status"
          get :latest_location, to: "delivery_locations#latest"
        end
      end

      # Ubicaciones GPS del repartidor
      resources :delivery_locations, only: :create

      # Admin
      resources :users, only: %i[index update]
      resource :settings, only: %i[show update], controller: "settings"
      resource :dashboard, only: :show, controller: "dashboard"
      resource :daily_stock, only: %i[show update], controller: "daily_stocks"
    end
  end
end
