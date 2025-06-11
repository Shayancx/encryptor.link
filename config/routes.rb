Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      get :health, to: "health#index"
      get :health, to: "health#index"
      resources :messages, only: [:create, :show, :destroy] do
        member do
          post :view
        end
      end
      resources :files, only: [:create, :show]
      get :health, to: 'messages#health'
    end
  end
  
  # Serve Vite app from Rails in development
  if Rails.env.development?
    # Special handling for API routes, but catch-all for other routes
    get "*path", to: "application#frontend_index_html", constraints: lambda { |request|
      !request.xhr? && request.format.html? && !request.path.start_with?('/api/')
    }
  end
  
  # Root path
  root "application#frontend_index_html"
end
