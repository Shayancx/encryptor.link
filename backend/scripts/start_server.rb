#!/usr/bin/env ruby
# frozen_string_literal: true

puts '🚀 Starting Encryptor.link Backend Server...'

# Load bundler and dependencies
require 'bundler/setup'

# Set up database if needed
unless File.exist?('db/encryptor.db')
  puts '📦 Setting up database for first time...'
  system('ruby scripts/setup_database.rb')
end

# Load the application
require_relative '../app'

# Start the server
puts '🌐 Server starting on http://localhost:9292'
puts "🔗 Frontend should be available at #{Environment.frontend_url}"
puts "📧 Email system: #{Environment.email_enabled? ? 'Enabled' : 'Disabled'}"
puts
puts 'Press Ctrl+C to stop the server'

# This would normally start Puma, but we'll let the user do that
puts 'Run: bundle exec rackup -p 9292'
