Rails.application.routes.draw do
  # API routes for frontend
  namespace :api do
    namespace :v1 do
      resources :messages, only: [:create, :show, :destroy] do
        member do
          post :view
        end
      end
      get :health, to: "health#index"
    end
  end
  
  # Health check
  get '/health', to: 'health#show'
  
  # Frontend SPA routes - catch all except API
  get "*path", to: "frontend#index", constraints: lambda { |request|
    !request.xhr? && 
    request.format.html? && 
    !request.path.start_with?('/api/') &&
    !request.path.start_with?('/health')
  }
  
  # Root path
  root "frontend#index"
end
