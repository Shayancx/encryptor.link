source "https://rubygems.org"

ruby "3.4.3", prism: true

# Rails
gem "rails", "8.0.2"
gem "pg"
gem "puma"

# Assets
gem "bootstrap", "~> 5.3"
gem "sassc-rails"
gem "sprockets-rails"
gem "importmap-rails"
gem "stimulus-rails"

# Use Redis for Action Cable
gem "redis", ">= 4.0.1"

# Use Active Storage variants
gem "image_processing", "~> 1.2"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  gem "web-console"
end

# Pagination
gem "pagy", "~> 6.0"

# Gems for CI workflow
group :development, :test do
  gem "brakeman", require: false  # Security scanner
  gem "rubocop-rails-omakase", require: false  # Rails style guide
  gem "rubocop", require: false  # Ruby style checker
end
