# Only apply these settings in development
if Rails.env.development?
  # Always disable rate limiting in development by default
  Rack::Attack.enabled = false

  puts "⚠️  Rate limiting disabled in development (Rack::Attack.enabled=false)"

  # Enable by setting RACK_ATTACK_ENABLED=true when running the server
  if ENV["RACK_ATTACK_ENABLED"] == "true"
    Rack::Attack.enabled = true
    puts "⚠️  Rate limiting enabled in development (RACK_ATTACK_ENABLED=true)"
  end
end
