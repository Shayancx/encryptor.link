# Debug initializer - only runs in development
if Rails.env.development?
  # Configure logging for development
  Rails.application.configure do
    # Enable debug logging
    config.log_level = :debug
    
    # More concise SQL logs
    config.active_record.verbose_query_logs = true
    
    # Configure request logging (compatible with Rails 8)
    config.log_tags = [
      :request_id,
      ->(request) { "#{request.request_method} #{request.fullpath}" }
    ]
  end

  # Custom formatter for ActiveRecord logs if needed
  if ActiveRecord::Base.logger
    ActiveRecord::Base.logger.formatter = proc do |severity, time, progname, msg|
      "\n\033[34m[#{time.strftime('%H:%M:%S')}] #{severity}\033[0m #{msg}\n"
    end
  end
end
