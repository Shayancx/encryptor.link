# frozen_string_literal: true

require 'dotenv'

# Load environment-specific .env file
env_file = case ENV['RACK_ENV']
           when 'production'
             '.env.production'
           when 'test'
             '.env.test'
           else
             '.env.development'
           end

Dotenv.load(env_file) if File.exist?(env_file)

# Environment configuration module
module Environment
  def self.development?
    ENV['RACK_ENV'] == 'development'
  end

  def self.production?
    ENV['RACK_ENV'] == 'production'
  end

  def self.test?
    ENV['RACK_ENV'] == 'test'
  end

  # Database
  def self.database_url
    ENV.fetch('DATABASE_URL', 'sqlite://db/encryptor.db')
  end

  # Security
  def self.jwt_secret
    ENV.fetch('JWT_SECRET') do
      raise 'JWT_SECRET must be set in production' if production?

      'development-jwt-secret-key'
    end
  end

  def self.bcrypt_cost
    ENV.fetch('BCRYPT_COST', development? ? '10' : '12').to_i
  end

  # CORS
  def self.frontend_url
    ENV.fetch('FRONTEND_URL', development? ? 'http://localhost:3000' : 'https://encryptor.link')
  end

  # Email
  def self.email_enabled?
    ENV.fetch('EMAIL_ENABLED', 'false') == 'true'
  end

  def self.smtp_config
    {
      host: ENV.fetch('SMTP_HOST', 'localhost'),
      port: ENV.fetch('SMTP_PORT', '1025').to_i,
      user: ENV['SMTP_USER'],
      password: ENV['SMTP_PASSWORD'],
      from: ENV.fetch('SMTP_FROM', 'noreply@encryptor.link')
    }
  end

  # File Upload
  def self.max_file_size_anonymous
    ENV.fetch('MAX_FILE_SIZE_ANONYMOUS', '104857600').to_i # 100MB default
  end

  def self.max_file_size_authenticated
    ENV.fetch('MAX_FILE_SIZE_AUTHENTICATED', '4294967296').to_i # 4GB default
  end

  def self.max_file_size_absolute
    ENV.fetch('MAX_FILE_SIZE_ABSOLUTE', '5368709120').to_i # 5GB default
  end

  # Rate Limiting
  def self.rate_limit_upload
    ENV.fetch('RATE_LIMIT_UPLOAD', '10').to_i
  end

  def self.rate_limit_download
    ENV.fetch('RATE_LIMIT_DOWNLOAD', '30').to_i
  end

  def self.rate_limit_window
    ENV.fetch('RATE_LIMIT_WINDOW', '60').to_i
  end

  # Cleanup
  def self.cleanup_interval_hours
    ENV.fetch('CLEANUP_INTERVAL_HOURS', '6').to_i
  end

  def self.default_file_ttl_hours
    ENV.fetch('DEFAULT_FILE_TTL_HOURS', '24').to_i
  end

  def self.max_file_ttl_hours
    ENV.fetch('MAX_FILE_TTL_HOURS', '168').to_i
  end
end
