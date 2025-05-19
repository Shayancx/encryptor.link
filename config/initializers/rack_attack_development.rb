# Only apply these settings in development
if Rails.env.development?
  # Set up easier testing in development
  Rack::Attack.enabled = (ENV["RACK_ATTACK_ENABLED"] != "false")
  
  # Allow disabling rate limiting by setting RACK_ATTACK_ENABLED=false when running the server
  if !Rack::Attack.enabled
    puts "⚠️  Rate limiting disabled in development (RACK_ATTACK_ENABLED=false)"
  end
end
