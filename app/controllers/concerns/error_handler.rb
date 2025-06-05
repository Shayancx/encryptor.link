# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      handle_error(e)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      render_error("Resource not found", :not_found)
    end

    rescue_from ActionController::ParameterMissing do |e|
      render_error("Missing parameter: #{e.param}", :bad_request)
    end
  end

  private

  def handle_error(error)
    Rails.logger.error "#{error.class}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    if Rails.env.production?
      render_error("An unexpected error occurred", :internal_server_error)
    else
      render_error(error.message, :internal_server_error)
    end
  end

  def render_error(message, status)
    respond_to do |format|
      format.json { render json: { error: message }, status: status }
      format.html { render plain: message, status: status }
    end
  end
end
