class ApplicationController < ActionController::Base
  # Skip CSRF verification for API endpoints
  skip_before_action :verify_authenticity_token, if: :json_request?
  
  # Set security headers
  before_action :set_security_headers
  
  # Frontend handler for SPA
  def frontend
    if Rails.env.development?
      # In development, let Vite handle the frontend
      render plain: 'Please access the frontend at http://localhost:5173', status: :ok
    else
      # In production, serve the built index.html
      render file: Rails.root.join('public', 'index.html'), layout: false
    end
  end
  
  protected
  
  # Check if the request expects JSON
  def json_request?
    request.format.json? || 
    request.headers['Content-Type']&.include?('application/json') ||
    request.headers['Accept']&.include?('application/json') ||
    request.path.start_with?('/api')
  end
  
  def set_security_headers
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    response.headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'
    
    # Set a strong CSP for API endpoints
    if request.path.start_with?('/api')
      response.headers['Content-Security-Policy'] = "default-src 'none'; frame-ancestors 'none';"
    end
  end
end
