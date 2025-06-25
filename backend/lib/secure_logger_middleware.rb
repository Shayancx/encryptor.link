# frozen_string_literal: true

# Middleware to filter sensitive data from logs
class SecureLoggerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    # Filter query strings - handle all password parameters
    env['QUERY_STRING'] = filter_passwords(env['QUERY_STRING']) if env['QUERY_STRING']&.include?('password')

    # Filter request URIs
    env['REQUEST_URI'] = filter_passwords(env['REQUEST_URI']) if env['REQUEST_URI']&.include?('password')

    @app.call(env)
  end

  private

  def filter_passwords(string)
    # Filter all password-related parameters
    string.gsub(/(\w*password\w*=)[^&]+/i, '\1[FILTERED]')
  end
end
