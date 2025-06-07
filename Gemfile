source "https://rubygems.org"

ruby "3.4.4", prism: true

# Rails
gem "rails", "8.0.2"
gem "pg"
gem "puma"
gem "csv"
gem "rodauth-rails"
gem "gpgme"

# Assets
gem "bootstrap", "~> 5.3"
gem "sassc-rails"
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
# Enables Sequel to use Active Record's database connection
gem "sequel-activerecord_connection", "~> 2.0", require: false
# Used by Rodauth for password hashing
gem "bcrypt", "~> 3.1", require: false
# Used by Rodauth for rendering built-in view and email templates
gem "tilt", "~> 2.4", require: false
