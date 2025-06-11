Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      resources :messages, only: [:index, :create, :show]
    end
  end
  
  # Serve frontend in development
  if Rails.env.development?
    get '*path', to: 'application#frontend_index_html', constraints: lambda { |request|
      !request.xhr? && request.format.html?
    }
  end
  
  # Root path
  root 'application#frontend_index_html'
end
