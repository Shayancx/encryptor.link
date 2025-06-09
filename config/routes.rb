Rails.application.routes.draw do
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

  get "/shadcn-test", to: "shadcn_test#index"
end

