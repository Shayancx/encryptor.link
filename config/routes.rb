Rails.application.routes.draw do
  # Health check endpoint
  get "/health", to: "health#show"
  
  # Certificate routes
  get "/certificates/:id", to: "certificates#show", as: :certificate
  get "/certificates/verify/:hash", to: "certificates#verify", as: :verify_certificate
  
  # API routes for React app
  post   "/encrypt", to: "encryptions#create"
  get    "/:id/info", to: "decryptions#info", as: :payload_info
  get    "/:id/data", to: "decryptions#data",  as: :decrypt_data
  
  # Test route for development
  get "/test", to: proc { |env| [200, { "Content-Type" => "text/plain" }, ["Vite + React is working!"]] }
  
  # Serve React app for all main routes
  root   "application#react_app"
  get    "/check", to: "application#react_app"
  get    "/:id", to: "application#react_app", constraints: { id: /[0-9a-f-]+/ }
  
  # Catch-all for other routes
  get "*path", to: "application#react_app", constraints: lambda { |req|
    !req.path.start_with?('/rails/') && 
    !req.path.start_with?('/assets/') && 
    !req.path.start_with?('/vite/') &&
    !req.path.start_with?('/@vite/') &&
    !req.path.start_with?('/@id/') &&
    !req.path.start_with?('/@fs/')
  }
end
