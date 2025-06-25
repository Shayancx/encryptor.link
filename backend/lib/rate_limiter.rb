# frozen_string_literal: true

module RateLimiter
  WINDOW_SIZE = 60 # 1 minute
  MAX_REQUESTS = {
    '/api/upload' => 10,
    '/api/download' => 30,
    'default' => 60
  }.freeze

  class << self
    def check_rate_limit(db, ip, endpoint)
      # Count recent requests
      recent_count = db[:access_logs]
                     .where(ip_address: ip)
                     .where(endpoint: endpoint)
                     .where(Sequel.lit('accessed_at > ?', Time.now - WINDOW_SIZE))
                     .count

      limit = MAX_REQUESTS[endpoint] || MAX_REQUESTS['default']

      return { allowed: false, retry_after: WINDOW_SIZE } if recent_count >= limit

      # Log this access
      db[:access_logs].insert(
        ip_address: ip,
        endpoint: endpoint,
        accessed_at: Time.now
      )

      { allowed: true }
    end

    def cleanup_old_logs(db)
      db[:access_logs]
        .where(Sequel.lit('accessed_at < ?', Time.now - 3600))
        .delete
    end
  end
end
