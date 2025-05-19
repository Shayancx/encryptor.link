class ApplicationController < ActionController::Base
  include RateLimitLogger
  include Pagy::Backend
  protect_from_forgery with: :exception
end
