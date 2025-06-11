# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5173', '127.0.0.1:5173', 'localhost:3000', '127.0.0.1:3000'

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
