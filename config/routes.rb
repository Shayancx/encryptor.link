Rails.application.routes.draw do
  # Health check endpoint
  get "/health", to: "health#show"
  post   "/encrypt", to: "encryptions#create"
  get    "/:id",     to: "decryptions#show",  as: :decrypt
  get    "/:id/data", to: "decryptions#data",  as: :decrypt_data
  root   "encryptions#new"
end
