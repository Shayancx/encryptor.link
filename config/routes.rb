Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  post   "/encrypt", to: "encryptions#create"
  get    "/:id",     to: "decryptions#show",  as: :decrypt
  get    "/:id/data", to: "decryptions#data",  as: :decrypt_data
  root   "encryptions#new"
end
