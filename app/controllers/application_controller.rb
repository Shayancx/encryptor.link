class ApplicationController < ActionController::Base
  # Skip CSRF protection for API endpoints
  protect_from_forgery with: :null_session, if: :api_request?
  
  # Serve frontend in development
  def frontend_index_html
    if Rails.env.development?
      redirect_to 'http://localhost:5173', status: :temporary_redirect, allow_other_host: true
    else
      render file: Rails.root.join('public', 'index.html'), layout: false
    end
  end
  
  # Handle exceptions
  rescue_from StandardError do |exception|
    Rails.logger.error("Exception: #{exception.class}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n")) if Rails.env.development?
    
    respond_to do |format|
      format.html { raise exception unless api_request? }
      format.json { render json: { error: exception.message }, status: :internal_server_error }
    end
  end
  
  rescue_from ActionController::ParameterMissing do |exception|
    Rails.logger.error("Parameter missing: #{exception.message}")
    
    respond_to do |format|
      format.html { raise exception unless api_request? }
      format.json { render json: { error: exception.message }, status: :bad_request }
    end
  end
  
  rescue_from ActiveRecord::RecordNotFound do |exception|
    Rails.logger.error("Record not found: #{exception.message}")
    
    respond_to do |format|
      format.html { raise exception unless api_request? }
      format.json { render json: { error: 'Record not found' }, status: :not_found }
    end
  end
  
  private
  
  def api_request?
    request.path.start_with?('/api/')
  end
end
