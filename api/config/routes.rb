Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Admin root → redirige al panel de superadmin
  constraints subdomain: "admin" do
    root to: redirect("/superadmin/tenants"), as: :admin_root
  end

  # Landing page — two-brothers.shop (sin subdominio)
  root "landing#index"

  # Superadmin — accesible desde admin.two-brothers.shop (opera en schema public)
  # Autenticación: HTTP Basic con SUPERADMIN_USERNAME / SUPERADMIN_PASSWORD
  # Superadmin — accesible desde admin.two-brothers.shop (opera en schema public)
  # new/edit se declaran explícitamente porque api_only:true los suprime por defecto
  namespace :superadmin do
    get  "tenants/new",          to: "tenants#new",  as: :new_tenant
    get  "tenants/:id/edit",     to: "tenants#edit", as: :edit_tenant
    resources :tenants, only: %i[index create update destroy]

    resources :subscriptions, only: %i[index create] do
      member do
        patch :suspend
        patch :reactivate
      end
    end

    resources :exchange_rates, only: %i[index create edit update]

    resources :billing_periods, only: %i[index show] do
      member do
        patch :mark_paid
      end
      collection do
        post :generate
      end
    end
  end

  mount ActionCable.server => "/cable"

  # Auth — flujo OAuth redirect (Authorization Code Flow)
  # Registrar en Google Console: BASE_URL/auth/google/callback
  get "/auth/google",          to: "auth#new_oauth"
  get "/auth/google/callback", to: "auth#callback"

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
      post "auth/google", to: "auth#google"

      # Session
      delete "/session", to: "sessions#destroy"

      # Usuario autenticado
      get "/me", to: "users#me"
      patch "/me", to: "users#update_me"

      # Menú (público - sin auth para GET)
      resources :categories, only: %i[index create update destroy]
      resources :menu_items, only: %i[create update destroy] do
        member { delete :image, to: 'menu_items#destroy_image' }
      end

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
      resource :reports,   only: :show, controller: "reports"
      resources :daily_stocks, only: %i[index update], controller: "daily_stocks"

      # Billing (solo lectura para el admin del tenant)
      resource :billing, only: :show, controller: "billing"
    end
  end
end
