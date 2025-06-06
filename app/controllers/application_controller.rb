class ApplicationController < ActionController::Base
  include RateLimitLogger
  include Auditable
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper
  protect_from_forgery with: :exception
end
