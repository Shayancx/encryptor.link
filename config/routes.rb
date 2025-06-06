Rails.application.routes.draw do
  namespace :admin do
    resources :audit_logs, only: [:index]
  end
  # Health check endpoint
  get "/health", to: "health#show"
  post   "/encrypt", to: "encryptions#create"
  get    "/check", to: "payload_infos#new", as: :check_link
  get    "/:id/info", to: "decryptions#info", as: :payload_info
  get    "/:id",     to: "decryptions#show",  as: :decrypt
  get    "/:id/data", to: "decryptions#data",  as: :decrypt_data
  root   "encryptions#new"
end
