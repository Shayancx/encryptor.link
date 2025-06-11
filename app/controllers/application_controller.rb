class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  # Serve frontend in development
  def frontend_index_html
    render file: Rails.root.join('public', 'index.html')
  end
  
  # Add CSRF token to JSON responses
  def set_csrf_token_header
    response.headers['X-CSRF-Token'] = form_authenticity_token
  end
  
  # Handle exceptions
  rescue_from StandardError do |exception|
    handle_error(exception, :internal_server_error)
  end
  
  rescue_from ActionController::ParameterMissing do |exception|
    handle_error(exception, :bad_request)
  end
  
  rescue_from ActiveRecord::RecordNotFound do |exception|
    handle_error(exception, :not_found)
  end
  
  private
  
  def handle_error(exception, status)
    Rails.logger.error("#{exception.class}: #{exception.message}")
    
    respond_to do |format|
      format.html { raise exception }
      format.json { render json: { error: exception.message }, status: status }
    end
  end
end
