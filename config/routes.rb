Rails.application.routes.draw do
  # API routes
  namespace :api do
    # Define your API endpoints here
  end
  
  # Serve frontend for all other routes
  get '*path', to: 'frontend#index', constraints: ->(req) { !req.xhr? && req.format.html? }
  root 'frontend#index'
end
