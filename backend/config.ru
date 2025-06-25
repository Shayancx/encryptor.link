# frozen_string_literal: true

require_relative 'app'
require_relative 'lib/secure_logger_middleware'

# Use secure logging middleware
use SecureLoggerMiddleware

# Only bind to localhost for security
if ENV['RACK_ENV'] == 'production'
  set :bind, '127.0.0.1'
  set :port, 9292
end

run EncryptorAPI.freeze.app
