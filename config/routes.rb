Rails.application.routes.draw do
  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :audit_logs, only: [ :index, :show ] do
      collection do
        post :export
        get :stats
        get :dashboard
      end
    end
  end
  mount RodauthApp, at: "/auth"

  get  "/register", to: "pgp_registrations#new", as: :register
  post "/register", to: "pgp_registrations#create"
  post "/register/verify", to: "pgp_registrations#verify", as: :verify_pgp_registration
  get  "/pgp_login", to: "pgp_sessions#new", as: :pgp_login_form
  post "/pgp_login", to: "pgp_sessions#create", as: :pgp_login

  resources :pgp_challenges, only: [ :create ] do
    collection do
      post :verify
    end
  end
  # Health check endpoint
  get "/health", to: "health#show"
  get "/certificates/:id", to: "certificates#show", as: :certificate
  get "/certificates/verify/:hash", to: "certificates#verify", as: :verify_certificate
  post   "/encrypt", to: "encryptions#create"
  get    "/check", to: "payload_infos#new", as: :check_link
  get    "/:id/info", to: "decryptions#info", as: :payload_info
  get    "/:id",     to: "decryptions#show",  as: :decrypt
  get    "/:id/data", to: "decryptions#data",  as: :decrypt_data
  root   "encryptions#new"
end
