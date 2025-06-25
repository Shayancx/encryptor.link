#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'sequel'
require_relative '../lib/file_storage'

# Connect to database
DB = Sequel.sqlite('db/encryptor.db')

class DatabaseMaintenance
  def self.run_cleanup
    puts '🧹 Running database maintenance...'

    # Clean up expired files
    expired_files = DB[:encrypted_files].where(Sequel.lit('expires_at < ?', Time.now))
    expired_count = expired_files.count

    if expired_count.positive?
      puts "🗑️  Cleaning up #{expired_count} expired files..."
      expired_files.each do |file|
        FileStorage.delete_file(file[:file_path]) if file[:file_path]
      end
      expired_files.delete
      puts "✓ Removed #{expired_count} expired files"
    end

    # Clean up old access logs (keep last 30 days)
    old_logs = DB[:access_logs].where(Sequel.lit('accessed_at < ?', Time.now - (30 * 24 * 3600)))
    old_log_count = old_logs.count

    if old_log_count.positive?
      puts "🗑️  Cleaning up #{old_log_count} old access logs..."
      old_logs.delete
      puts "✓ Removed #{old_log_count} old access logs"
    end

    # Clean up expired password reset tokens
    expired_tokens = DB[:password_reset_tokens].where(Sequel.lit('expires_at < ? OR used = ?', Time.now, true))
    expired_token_count = expired_tokens.count

    if expired_token_count.positive?
      puts "🗑️  Cleaning up #{expired_token_count} expired/used reset tokens..."
      expired_tokens.delete
      puts "✓ Removed #{expired_token_count} expired/used tokens"
    end

    # VACUUM database to reclaim space
    puts '🔧 Optimizing database...'
    DB.execute('VACUUM')
    puts '✓ Database optimized'

    puts '✅ Maintenance completed!'
  end

  def self.show_stats
    puts '📊 Database Statistics:'
    puts "  Encrypted files: #{DB[:encrypted_files].count}"
    puts "  Active accounts: #{DB[:accounts].count}"
    puts "  Access logs (last 7 days): #{DB[:access_logs].where(Sequel.lit('accessed_at > ?',
                                                                           Time.now - (7 * 24 * 3600))).count}"
    puts "  Pending reset tokens: #{DB[:password_reset_tokens].where(Sequel.lit('expires_at > ? AND used = ?',
                                                                                Time.now, false)).count}"

    # File storage stats
    total_size = DB[:encrypted_files].sum(:file_size) || 0
    puts "  Total storage used: #{(total_size / 1024.0 / 1024.0).round(2)} MB"
  end
end

# Run based on command line argument
case ARGV[0]
when 'cleanup'
  DatabaseMaintenance.run_cleanup
when 'stats'
  DatabaseMaintenance.show_stats
when 'all'
  DatabaseMaintenance.show_stats
  puts
  DatabaseMaintenance.run_cleanup
else
  puts 'Usage: ruby maintenance.rb [cleanup|stats|all]'
  puts '  cleanup - Clean up expired files and logs'
  puts '  stats   - Show database statistics'
  puts '  all     - Show stats then run cleanup'
end

# Clean up streaming upload sessions
puts '🗑️  Cleaning up streaming upload sessions...'
StreamingUpload.cleanup_old_sessions
puts '✓ Streaming sessions cleaned'

# Clean up streaming upload sessions
puts '🗑️  Cleaning up streaming upload sessions...'
StreamingUpload.cleanup_old_sessions
puts '✓ Streaming sessions cleaned'
