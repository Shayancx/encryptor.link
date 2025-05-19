module RateLimitLogger
  extend ActiveSupport::Concern

  included do
    # Subscribe to rate limiting events
    ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
      req = payload[:request]
      if req.env["rack.attack.matched"] && req.env["rack.attack.match_type"] == :throttle
        Rails.logger.warn("Rate limit exceeded for #{req.ip} on #{req.path}")
      end
    end
  end
end
