Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resources :messages, only: [:create, :show]
      resources :files, only: [:show]
      get 'health', to: 'health#index'
    end
  end
  
  # Frontend route - catch all for SPA
  get '*path', to: 'application#frontend', constraints: ->(request) {
    !request.xhr? && request.format.html?
  }
  
  # Root path
  root 'application#frontend'
end
