Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resources :messages, only: [:create, :show] do
        member do
          post :view
        end
        resources :files, only: [:show], param: :file_name
      end
      get 'health', to: 'health#index'
    end
  end
  
  # Frontend routes - these are handled by the React app
  get '/message/:id', to: 'application#frontend'
  
  # Root path
  root 'application#frontend'
  
  # Catch all for React Router - must be last
  get '*path', to: 'application#frontend', constraints: ->(request) {
    !request.xhr? && request.format.html?
  }
end
