class ApplicationController < ActionController::Base
  # Skip CSRF verification for API endpoints
  skip_before_action :verify_authenticity_token, if: :json_request?
  
  # Frontend handler for SPA
  def frontend
    render file: Rails.root.join('public', 'index.html')
  end
  
  protected
  
  # Check if the request expects JSON
  def json_request?
    request.format.json? || 
    request.headers['Content-Type']&.include?('application/json') ||
    request.headers['Accept']&.include?('application/json')
  end
end
