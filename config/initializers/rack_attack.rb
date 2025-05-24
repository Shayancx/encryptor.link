# Rack Attack for rate limiting
class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Throttle encryption endpoint (POST /encrypt)
  throttle("req/ip/encrypt", limit: 10, period: 60.seconds) do |req|
    req.ip if req.path == "/encrypt" && req.post?
  end

  # Throttle decryption data endpoint (GET /:id/data)
  # Increased from 20 to 30 per minute to ensure adequate testing
  throttle("req/ip/decrypt_data", limit: 30, period: 60.seconds) do |req|
    req.ip if req.path.match(/\/[^\/]+\/data/) && req.get?
  end

  # Throttle overall requests per IP (increased from 300 to 500)
  throttle("req/ip", limit: 500, period: 5.minutes) do |req|
    req.ip
  end

  # Block IPs that attempt to access more than 30 distinct payload IDs in 15 minutes
  # This helps prevent scanning/enumeration attacks
  throttle("payloads/ip", limit: 40, period: 15.minutes) do |req|
    if req.path.match(/\/[^\/]+\/data/) && req.get?
      req.ip
    end
  end

  # Skip rate limiting for local development and testing
  safelist("local-network") do |req|
    # Allow localhost and private networks to bypass rate limiting when in development
    if Rails.env.development?
      req.ip == "127.0.0.1" || req.ip.start_with?("192.168.") || req.ip.start_with?("10.")
    end
  end

  # Add response headers for throttled requests
  self.throttled_responder = lambda do |env|
    retry_after = (env["rack.attack.match_data"] || {})[:period]
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [ { error: "Rate limit exceeded. Please try again later." }.to_json ]
    ]
  end
end
