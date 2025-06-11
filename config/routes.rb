Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resources :messages, only: [:create, :show, :destroy] do
        member do
          post :view
        end
      end
      resources :files, only: [:create, :show]
      get :health, to: "health#index"
    end
  end
  
  # Main encryption endpoints (for Rails views if needed)
  get '/encrypt', to: 'encryptions#new'
  post '/encrypt', to: 'encryptions#create'
  get '/:id/data', to: 'decryptions#data'
  get '/:id/info', to: 'decryptions#info'
  get '/:id', to: 'decryptions#show'
  
  # Health check
  get '/health', to: 'health#show'
  
  # Certificate routes
  get '/certificates/:id', to: 'certificates#show'
  get '/certificates/verify/:hash', to: 'certificates#verify'
  
  # Payload info
  get '/check', to: 'payload_infos#new'
  
  # Frontend routes - catch all for SPA
  get "*path", to: "frontend#index", constraints: lambda { |request|
    !request.xhr? && 
    request.format.html? && 
    !request.path.start_with?('/api/') &&
    !request.path.start_with?('/health') &&
    !request.path.start_with?('/encrypt') &&
    !request.path.start_with?('/certificates') &&
    !request.path.start_with?('/check') &&
    !request.path.match(/^\/[a-f0-9-]{36}/)
  }
  
  # Root path
  root "frontend#index"
end
