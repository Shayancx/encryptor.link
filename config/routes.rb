Rails.application.routes.draw do
  # Authentication routes
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [:new, :create]

  # Core functionality (accessible without login)
  post   "/encrypt", to: "encryptions#create"
  get    "/:id",     to: "decryptions#show",  as: :decrypt
  get    "/:id/data", to: "decryptions#data",  as: :decrypt_data
  root   "encryptions#new"

  # Account functionality (requires login)
  namespace :account do
    resource :dashboard, only: [:show]
    resources :messages, only: [:index, :show, :update, :destroy]
    resource :preferences, only: [:show, :update]
    resource :security, only: [:show] do
      post :update_password
    end
    resource :statistics, only: [:show]
  end
end
