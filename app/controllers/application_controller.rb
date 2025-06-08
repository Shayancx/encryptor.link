class ApplicationController < ActionController::Base
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper
  protect_from_forgery with: :exception
end
