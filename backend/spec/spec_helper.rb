# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/db/'
  add_filter '/scripts/'
  minimum_coverage 90
end

ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.require(:default, :test)

require_relative '../app'
require_relative '../lib/crypto'
require_relative '../lib/file_storage'
require_relative '../lib/rate_limiter'
require_relative '../lib/services/email_service'
require_relative '../lib/secure_logger_middleware'
require_relative '../config/environment'

require 'rack/test'
require 'rspec'
require 'factory_bot'
require 'faker'
require 'database_cleaner/sequel'
require 'timecop'
require 'webmock/rspec'
require 'rspec/json_expectations'
require 'rspec-benchmark'
require 'fileutils'

# Test database
TEST_DB_PATH = 'db/test.db'
FileUtils.rm_f(TEST_DB_PATH)
TEST_DB = Sequel.sqlite(TEST_DB_PATH)

# Run migrations on test database
Sequel.extension :migration
Sequel::Migrator.run(TEST_DB, 'db/migrations')

# Configure RSpec
RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include RSpec::Benchmark::Matchers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # Database cleaner
  config.before(:suite) do
    DatabaseCleaner[:sequel].db = TEST_DB
    DatabaseCleaner[:sequel].strategy = :transaction
    DatabaseCleaner[:sequel].clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner[:sequel].cleaning do
      example.run
    end
  end

  # Test file cleanup
  config.after(:suite) do
    FileUtils.rm_rf('storage/test')
    FileUtils.rm_f(TEST_DB_PATH)
  end

  # Helper to get app instance
  def app
    EncryptorAPI.freeze.app
  end

  # Helper to create test files
  def create_test_file(content = 'test content', filename = 'test.txt')
    file_path = "tmp/#{filename}"
    File.write(file_path, content)
    file_path
  end

  # Helper to create auth token
  def create_auth_token(account_id, email)
    SimpleJWT.encode({ account_id: account_id, email: email })
  end

  # Stub environment for tests
  config.before(:each) do
    allow(Environment).to receive(:jwt_secret).and_return('test-secret-key')
    allow(Environment).to receive(:email_enabled?).and_return(false)
    allow(Environment).to receive(:development?).and_return(false)
    allow(Environment).to receive(:frontend_url).and_return('http://localhost:3000')
  end
end

# Load support files
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

# Add helper to create test users
def create_test_user(email = nil)
  email ||= "test_#{SecureRandom.hex(4)}@example.com"
  password_hash = BCrypt::Password.create('TestP@ssw0rd123!')

  id = TEST_DB[:accounts].insert(
    email: email,
    password_hash: password_hash,
    status_id: 'verified',
    created_at: Time.now
  )

  TEST_DB[:accounts].where(id: id).first
end

# Enhanced cleanup between tests
RSpec.configure do |config|
  # Clean storage directory after each test
  config.after(:each) do
    FileUtils.rm_rf('storage/test') if Dir.exist?('storage/test')
    # Ensure tmp directory exists for tests
    FileUtils.mkdir_p('tmp')
  end

  # Clear all test data before suite
  config.before(:suite) do
    TEST_DB[:encrypted_files].delete
    TEST_DB[:accounts].delete
    TEST_DB[:access_logs].delete
    TEST_DB[:password_reset_tokens].delete if TEST_DB.tables.include?(:password_reset_tokens)
  end
end
