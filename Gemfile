source "https://rubygems.org"

ruby "3.4.4", prism: true

# Rails
gem "rails", "8.0.2"
gem "pg"
gem "puma"

# Assets
gem "sprockets-rails"

# Reduces boot times through caching
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
  gem "capybara"
  gem "selenium-webdriver"
  gem "timecop"
  gem "simplecov", require: false
end

group :development do
  gem "web-console"
  gem "brakeman"
  gem "rubocop-rails-omakase", require: false
  gem "rubocop", require: false
end

# Rate limiting
gem "rack-attack"

# Testing dependencies
group :test do
  gem "rails-controller-testing"
end
gem 'rack-cors', require: 'rack/cors'
gem 'secure_headers', '~> 6.4'

# Vite integration
gem 'vite_rails'
