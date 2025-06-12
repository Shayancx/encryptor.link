Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.production?
      origins 'https://encryptor.link'
    else
      origins 'http://localhost:5173', 'http://localhost:3000'
    end
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: true,
      max_age: 86400
  end
end
