# frozen_string_literal: true

# Puma configuration for production with security
workers ENV.fetch('WEB_CONCURRENCY', 2)
threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
threads threads_count, threads_count

preload_app!

port        ENV.fetch('PORT', 9292)
environment ENV.fetch('RACK_ENV', 'development')

# Only bind to localhost in production
if ENV['RACK_ENV'] == 'production'
  bind 'tcp://127.0.0.1:9292'
else
  bind 'tcp://0.0.0.0:9292'
end

pidfile ENV.fetch('PIDFILE', 'tmp/pids/server.pid')

# Custom log formatter that filters sensitive data
class SecureLogFormatter
  def call(str)
    # Remove password parameters from logs
    filtered = str.gsub(/password=[^&\s]+/, 'password=[FILTERED]')
    filtered.gsub(/"password":"[^"]+"/, '"password":"[FILTERED]"')
  end
end

# Configure logging
on_worker_boot do
  # Override default logging to filter passwords
  if defined?(::Rack::CommonLogger)
    ::Rack::CommonLogger.class_eval do
      alias_method :original_log, :log

      def log(env, status, header, began_at)
        # Filter sensitive data from env
        env['QUERY_STRING'] = env['QUERY_STRING'].gsub(/password=[^&]+/, 'password=[FILTERED]') if env['QUERY_STRING']
        original_log(env, status, header, began_at)
      end
    end
  end
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
