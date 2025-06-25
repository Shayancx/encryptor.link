# frozen_string_literal: true

# Security configuration
module SecurityConfig
  # Bcrypt cost factor (12 is recommended for production)
  BCRYPT_COST = ENV['RACK_ENV'] == 'production' ? 12 : 10

  # Password requirements
  PASSWORD_MIN_LENGTH = 8
  PASSWORD_REQUIRE_UPPERCASE = true
  PASSWORD_REQUIRE_LOWERCASE = true
  PASSWORD_REQUIRE_NUMBER = true
  PASSWORD_REQUIRE_SPECIAL = true

  # Session settings
  SESSION_TIMEOUT = 3600 # 1 hour

  # Rate limiting
  MAX_LOGIN_ATTEMPTS = 5
  LOCKOUT_DURATION = 900 # 15 minutes

  # Security headers
  SECURITY_HEADERS = {
    'X-Frame-Options' => 'DENY',
    'X-Content-Type-Options' => 'nosniff',
    'X-XSS-Protection' => '1; mode=block',
    'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains',
    'Content-Security-Policy' => "default-src 'self'"
  }.freeze
end
