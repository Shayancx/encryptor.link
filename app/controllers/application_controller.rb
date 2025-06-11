class ApplicationController < ActionController::Base
  def frontend_index_html
    render file: Rails.root.join('public', 'index.html')
  end
end
