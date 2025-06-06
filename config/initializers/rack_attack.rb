# Rack Attack for rate limiting
class Rack::Attack
  ### Configure Cache ###
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Throttle encryption endpoint (POST /encrypt)
  throttle("req/ip/encrypt", limit: 10, period: 60.seconds) do |req|
    req.ip if req.path == "/encrypt" && req.post?
  end

  # Throttle decryption data endpoint (GET /:id/data)
  throttle("req/ip/decrypt_data", limit: 30, period: 60.seconds) do |req|
    req.ip if req.path.match(/\/[^\/]+\/data/) && req.get?
  end

  throttle("req/ip/payload_info", limit: 60, period: 60.seconds) do |req|
    req.ip if req.path.match(/\/[^\/]+\/info/) && req.get?
  end

  # Throttle overall requests per IP
  throttle("req/ip", limit: 500, period: 5.minutes) do |req|
    req.ip
  end

  # Block IPs that attempt to access more than 40 distinct payload IDs in 15 minutes
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

  # Use the new throttled_responder method
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => (match_data[:period] - (now % match_data[:period])).to_s
    }
    [ 429, headers, [ { error: "Rate limit exceeded. Please try again later." }.to_json ] ]
  end

  # Integrate with audit logging
  ActiveSupport::Notifications.subscribe(/rack\.attack/) do |name, start, finish, request_id, payload|
    req = payload[:request]

    if req.env['rack.attack.matched']
      event_type = case req.env['rack.attack.match_type']
                   when :throttle
                     AuditService::EVENTS[:rate_limit_exceeded]
                   when :blocklist
                     AuditService::EVENTS[:blocked_request]
                   when :safelist
                     AuditService::EVENTS[:safelisted_request]
                   else
                     AuditService::EVENTS[:suspicious_activity]
                   end

      AuditService.log(
        event_type: event_type,
        request: req,
        metadata: {
          throttle_name: req.env['rack.attack.matched'],
          match_type: req.env['rack.attack.match_type'],
          discriminator: req.env['rack.attack.match_discriminator'],
          match_data: req.env['rack.attack.match_data']
        },
        severity: 'warning'
      )
    end
  end
end
