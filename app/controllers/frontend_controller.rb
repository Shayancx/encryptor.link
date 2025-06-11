class FrontendController < ApplicationController
  def index
    # In development, redirect to Vite server
    if Rails.env.development?
      redirect_to 'http://localhost:5173', status: :temporary_redirect, allow_other_host: true
    else
      # In production, serve the built static files
      render file: Rails.root.join('public', 'index.html'), layout: false
    end
  end
end
