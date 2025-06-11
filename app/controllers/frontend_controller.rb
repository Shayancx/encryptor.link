class FrontendController < ApplicationController
  def index
    # Serve the Vite-built frontend in production, or development proxy
    if Rails.env.production?
      render file: Rails.root.join('public', 'index.html'), layout: false
    else
      # In development, redirect to Vite dev server
      redirect_to 'http://localhost:5173', status: :temporary_redirect, allow_other_host: true
    end
  end
end
