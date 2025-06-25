#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'sequel'
require 'fileutils'

# Ensure database directory exists
FileUtils.mkdir_p('db')
FileUtils.mkdir_p('logs')

# Connect to database
DB = Sequel.sqlite('db/encryptor.db')

puts '🗄️  Setting up Encryptor.link database...'

# Enable WAL mode for better concurrency
DB.execute('PRAGMA journal_mode = WAL')
DB.execute('PRAGMA synchronous = NORMAL')
DB.execute('PRAGMA cache_size = 10000')
DB.execute('PRAGMA temp_store = memory')
DB.execute('PRAGMA mmap_size = 268435456') # 256MB

puts '✓ Database optimizations applied'

# Run migrations
begin
  Sequel.extension :migration
  migration_dir = File.expand_path('../db/migrations', __dir__)

  if Dir.exist?(migration_dir)
    puts '🔄 Running database migrations...'
    Sequel::Migrator.run(DB, migration_dir)
    puts '✓ Migrations completed successfully'
  else
    puts '⚠️  No migrations directory found, creating base tables...'

    # Create base tables if no migrations exist
    create_base_tables
  end

  # Verify tables exist
  verify_database_structure

  puts '✅ Database setup completed successfully!'
  puts
  puts 'Database info:'
  puts "  Location: #{File.expand_path('db/encryptor.db')}"
  puts "  Tables: #{DB.tables.sort.join(', ')}"
  puts "  Total records: #{total_records}"
rescue StandardError => e
  puts "❌ Database setup failed: #{e.message}"
  puts e.backtrace.join("\n") if ENV['DEBUG']
  exit 1
end

def create_base_tables
  # Core tables
  DB.create_table?(:encrypted_files) do
    primary_key :id
    String :file_id, null: false, unique: true, size: 36
    String :password_hash, null: false, size: 60
    String :salt, null: false, size: 64
    String :file_path, null: false, text: true
    String :original_filename, size: 255
    String :mime_type, size: 100
    Integer :file_size, null: false
    String :encryption_iv, null: false, size: 32
    DateTime :created_at, null: false
    DateTime :expires_at
    String :ip_address, size: 45
    Bignum :account_id, null: true

    index :file_id, unique: true
    index :expires_at
    index :account_id
    index :created_at
  end

  DB.create_table?(:access_logs) do
    primary_key :id
    String :ip_address, null: false, size: 45
    String :endpoint, null: false, size: 100
    DateTime :accessed_at, null: false

    index %i[ip_address endpoint accessed_at]
  end

  # Authentication tables
  DB.create_table?(:accounts) do
    primary_key :id
    String :email, null: false, unique: true
    String :status_id, null: false, default: 'verified'
    String :password_hash, null: false, size: 60
    DateTime :created_at, null: false
    DateTime :updated_at
    DateTime :last_login_at

    index :email, unique: true
    index :status_id
  end

  DB.create_table?(:password_reset_tokens) do
    primary_key :id
    foreign_key :account_id, :accounts, null: false, on_delete: :cascade
    String :token, null: false, unique: true, size: 64
    DateTime :expires_at, null: false
    DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    Boolean :used, default: false

    index :token, unique: true
    index :account_id
    index :expires_at
  end

  puts '✓ Base tables created'
end

def verify_database_structure
  required_tables = %i[encrypted_files access_logs accounts password_reset_tokens]
  existing_tables = DB.tables

  missing_tables = required_tables - existing_tables
  raise "Missing required tables: #{missing_tables.join(', ')}" if missing_tables.any?

  # Verify account_id column exists in encrypted_files
  columns = DB[:encrypted_files].columns
  unless columns.include?(:account_id)
    puts '🔄 Adding account_id column to encrypted_files...'
    DB.alter_table(:encrypted_files) do
      add_column :account_id, :Bignum, null: true
      add_index :account_id
    end
    puts '✓ account_id column added'
  end

  puts '✓ Database structure verified'
end

def total_records
  DB.tables.map { |table| DB[table].count }.sum
end
