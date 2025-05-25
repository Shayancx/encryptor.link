class ApplicationController < ActionController::Base
  include Authentication
  include RateLimitLogger
  protect_from_forgery with: :exception
end
