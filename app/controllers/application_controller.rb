class ApplicationController < ActionController::Base
  include RateLimitLogger
  protect_from_forgery with: :exception
end
