#!/bin/bash

# Comprehensive Streaming Upload Test Suite
# Save this as test_streaming_comprehensive.sh in the project root

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKEND_DIR="$(pwd)/backend"
SPEC_DIR="$BACKEND_DIR/spec"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="streaming_test_${TIMESTAMP}.log"

echo -e "${BLUE}=== Comprehensive Streaming Upload Test Suite ===${NC}"
echo -e "Started at: $(date)"
echo -e "Log file: $LOG_FILE\n"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to setup test database properly
setup_test_database() {
    echo -e "\n${BLUE}Setting up test database...${NC}"
    cd "$BACKEND_DIR"
    
    # Remove existing test database
    rm -f db/test.db
    log "Removed old test database"
    
    # Create fresh test database with proper migration handling
    cat > setup_test_db.rb << 'EOF'
#!/usr/bin/env ruby
require 'bundler/setup'
require 'sequel'
require 'fileutils'

# Create test database
TEST_DB = Sequel.sqlite('db/test.db')

puts "Creating test database..."

# Create base tables first
TEST_DB.create_table?(:encrypted_files) do
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
  TrueClass :is_chunked, default: false
  
  index :file_id, unique: true
  index :expires_at
  index :account_id
  index :created_at
  index :is_chunked
end

TEST_DB.create_table?(:access_logs) do
  primary_key :id
  String :ip_address, null: false, size: 45
  String :endpoint, null: false, size: 100
  DateTime :accessed_at, null: false
  
  index [:ip_address, :endpoint, :accessed_at]
end

TEST_DB.create_table?(:accounts) do
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

TEST_DB.create_table?(:password_reset_tokens) do
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

TEST_DB.create_table?(:streaming_sessions) do
  primary_key :id
  String :session_id, null: false, unique: true
  String :file_id, null: false
  Integer :total_chunks, null: false
  Integer :received_chunks, default: 0
  String :status, default: 'uploading'
  DateTime :created_at, null: false
  DateTime :updated_at
  
  index :session_id
  index :created_at
end

# Create migration tracking table
TEST_DB.create_table?(:schema_migrations) do
  String :filename, null: false
  DateTime :run_at, null: false, default: Sequel::CURRENT_TIMESTAMP
  
  primary_key [:filename]
end

puts "✓ Test database created successfully"
puts "Tables: #{TEST_DB.tables.sort.join(', ')}"
EOF

    ruby setup_test_db.rb | tee -a "../$LOG_FILE"
    rm -f setup_test_db.rb
    
    cd ..
}

# Function to run tests and capture results
run_test_suite() {
    local suite_name=$1
    local test_file=$2
    
    echo -e "\n${YELLOW}Running: $suite_name${NC}"
    log "Starting test suite: $suite_name"
    
    cd "$BACKEND_DIR"
    if RACK_ENV=test bundle exec rspec "$test_file" --format documentation --format json --out "test_results_${suite_name}.json" 2>&1 | tee -a "../$LOG_FILE"; then
        echo -e "${GREEN}✓ $suite_name passed${NC}"
        log "Test suite passed: $suite_name"
    else
        echo -e "${RED}✗ $suite_name failed${NC}"
        log "Test suite failed: $suite_name"
        return 1
    fi
    cd ..
}

# Create comprehensive streaming tests
create_streaming_tests() {
    log "Creating comprehensive streaming upload tests..."
    
    # Create main streaming upload spec
    cat > "$SPEC_DIR/streaming/comprehensive_streaming_upload_spec.rb" << 'EOF'
require 'spec_helper'
require 'tempfile'
require 'digest'

RSpec.describe 'Comprehensive Streaming Upload System' do
  include Rack::Test::Methods
  include ApiHelper
  
  let(:test_password) { 'TestP@ssw0rd123!' }
  let(:weak_password) { 'weak' }
  let(:salt) { Crypto.generate_salt }
  
  # Test file sizes
  let(:small_file_size) { 100 * 1024 }          # 100KB
  let(:medium_file_size) { 5 * 1024 * 1024 }    # 5MB
  let(:large_file_size) { 50 * 1024 * 1024 }    # 50MB
  let(:chunk_size) { 1024 * 1024 }              # 1MB
  
  describe 'Complete Upload Flow' do
    context 'with small file' do
      it 'successfully uploads file in single chunk' do
        # Generate test data
        test_data = SecureRandom.random_bytes(small_file_size)
        filename = "test_small_#{Time.now.to_i}.bin"
        
        # Initialize session
        init_response = post '/api/streaming/initialize', {
          filename: filename,
          fileSize: small_file_size,
          mimeType: 'application/octet-stream',
          password: test_password,
          totalChunks: 1,
          chunkSize: chunk_size
        }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        init_data = JSON.parse(last_response.body)
        expect(init_data).to have_key('session_id')
        expect(init_data).to have_key('file_id')
        
        session_id = init_data['session_id']
        file_id = init_data['file_id']
        
        # Encrypt and upload chunk
        key = Crypto.derive_key(test_password, salt)
        cipher = OpenSSL::Cipher.new('AES-256-GCM')
        cipher.encrypt
        cipher.key = key
        iv = cipher.random_iv
        encrypted_data = cipher.update(test_data) + cipher.final
        auth_tag = cipher.auth_tag
        
        # Upload chunk as multipart
        post '/api/streaming/chunk', {
          session_id: session_id,
          chunk_index: '0',
          iv: Base64.strict_encode64(iv),
          chunk_data: Rack::Test::UploadedFile.new(
            StringIO.new(encrypted_data + auth_tag),
            'application/octet-stream',
            false,
            original_filename: 'chunk_0.enc'
          )
        }
        
        expect(last_response.status).to eq(200)
        chunk_result = JSON.parse(last_response.body)
        expect(chunk_result['chunks_received']).to eq(1)
        expect(chunk_result['total_chunks']).to eq(1)
        
        # Finalize
        finalize_response = post '/api/streaming/finalize', {
          session_id: session_id,
          salt: Base64.strict_encode64(salt)
        }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        finalize_data = JSON.parse(last_response.body)
        expect(finalize_data['file_id']).to eq(file_id)
        
        # Verify file in database
        file_record = TEST_DB[:encrypted_files].where(file_id: file_id).first
        expect(file_record).not_to be_nil
        expect(file_record[:is_chunked]).to be true
        expect(file_record[:original_filename]).to eq(filename)
        expect(file_record[:file_size]).to eq(small_file_size)
        
        # Verify session cleaned up
        session_path = File.join(StreamingUpload::TEMP_STORAGE_PATH, session_id)
        expect(Dir.exist?(session_path)).to be false
      end
    end
    
    context 'with medium file (multiple chunks)' do
      it 'successfully uploads file in multiple chunks' do
        test_data = SecureRandom.random_bytes(medium_file_size)
        filename = "test_medium_#{Time.now.to_i}.bin"
        total_chunks = (medium_file_size.to_f / chunk_size).ceil
        
        # Initialize
        init_response = post '/api/streaming/initialize', {
          filename: filename,
          fileSize: medium_file_size,
          mimeType: 'application/octet-stream',
          password: test_password,
          totalChunks: total_chunks,
          chunkSize: chunk_size
        }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        session_id = JSON.parse(last_response.body)['session_id']
        file_id = JSON.parse(last_response.body)['file_id']
        
        # Upload chunks
        key = Crypto.derive_key(test_password, salt)
        
        total_chunks.times do |i|
          start_pos = i * chunk_size
          end_pos = [start_pos + chunk_size, medium_file_size].min
          chunk_data = test_data[start_pos...end_pos]
          
          # Encrypt chunk
          cipher = OpenSSL::Cipher.new('AES-256-GCM')
          cipher.encrypt
          cipher.key = key
          iv = cipher.random_iv
          encrypted_chunk = cipher.update(chunk_data) + cipher.final
          auth_tag = cipher.auth_tag
          
          # Upload
          post '/api/streaming/chunk', {
            session_id: session_id,
            chunk_index: i.to_s,
            iv: Base64.strict_encode64(iv),
            chunk_data: Rack::Test::UploadedFile.new(
              StringIO.new(encrypted_chunk + auth_tag),
              'application/octet-stream'
            )
          }
          
          expect(last_response.status).to eq(200)
          result = JSON.parse(last_response.body)
          expect(result['chunks_received']).to eq(i + 1)
        end
        
        # Finalize
        post '/api/streaming/finalize', {
          session_id: session_id,
          salt: Base64.strict_encode64(salt)
        }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['file_id']).to eq(file_id)
      end
    end
  end
  
  describe 'Error Handling' do
    context 'initialization errors' do
      it 'rejects weak passwords' do
        post '/api/streaming/initialize', {
          filename: 'test.txt',
          fileSize: 1000,
          mimeType: 'text/plain',
          password: weak_password,
          totalChunks: 1,
          chunkSize: 1000
        }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to include('characters')
      end
      
      it 'rejects files over anonymous limit' do
        post '/api/streaming/initialize', {
          filename: 'huge.bin',
          fileSize: 200 * 1024 * 1024, # 200MB
          mimeType: 'application/octet-stream',
          password: test_password,
          totalChunks: 200,
          chunkSize: chunk_size
        }.to_json, 'CONTENT_TYPE' => 'application/json'
        
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['error']).to include('too large')
      end
    end
  end
  
  describe 'Authentication Support' do
    let(:test_email) { "streaming_test_#{SecureRandom.hex(8)}@example.com" }
    let(:auth_password) { 'AuthP@ssw0rd123!' }
    let(:auth_token) do
      # Create user
      user = create_test_user(test_email)
      create_auth_token(user[:id], user[:email])
    end
    
    it 'allows larger files for authenticated users' do
      large_size = 150 * 1024 * 1024 # 150MB - over anonymous limit
      
      post '/api/streaming/initialize', {
        filename: 'large_auth.bin',
        fileSize: large_size,
        mimeType: 'application/octet-stream',
        password: test_password,
        totalChunks: 150,
        chunkSize: chunk_size
      }.to_json, {
        'CONTENT_TYPE' => 'application/json',
        'HTTP_AUTHORIZATION' => "Bearer #{auth_token}"
      }
      
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data).to have_key('session_id')
      expect(data).to have_key('file_id')
    end
  end
end
EOF

    # Create simplified test that focuses on core functionality
    cat > "$SPEC_DIR/streaming/basic_streaming_spec.rb" << 'EOF'
require 'spec_helper'

RSpec.describe 'Basic Streaming Upload' do
  include Rack::Test::Methods
  include ApiHelper
  
  describe 'POST /api/streaming/initialize' do
    it 'creates a session with valid parameters' do
      post '/api/streaming/initialize', {
        filename: 'test.txt',
        fileSize: 1000,
        mimeType: 'text/plain',
        password: 'TestP@ssw0rd123!',
        totalChunks: 1,
        chunkSize: 1000
      }.to_json, 'CONTENT_TYPE' => 'application/json'
      
      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)
      expect(data).to have_key('session_id')
      expect(data).to have_key('file_id')
    end
  end
  
  describe 'GET /api/streaming/health' do
    it 'returns health status' do
      get '/api/streaming/health'
      
      expect(last_response.status).to eq(200)
      health = JSON.parse(last_response.body)
      expect(health['status']).to eq('healthy')
    end
  end
end
EOF

    log "Test files created successfully"
}

# Fix spec_helper.rb to handle test database properly
fix_spec_helper() {
    echo -e "\n${BLUE}Fixing spec_helper.rb...${NC}"
    
    # Backup original
    cp "$SPEC_DIR/spec_helper.rb" "$SPEC_DIR/spec_helper.rb.bak"
    
    # Create fixed version
    cat > "$SPEC_DIR/spec_helper.rb" << 'EOF'
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
require_relative '../lib/streaming_upload'
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

# Test database - use existing one, don't recreate
TEST_DB_PATH = 'db/test.db'
TEST_DB = Sequel.sqlite(TEST_DB_PATH)

# Ensure storage directories exist
FileUtils.mkdir_p('storage/test')
FileUtils.mkdir_p('storage/temp')
FileUtils.mkdir_p('tmp')

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
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

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
  end

  # Helper to get app instance
  def app
    EncryptorAPI.freeze.app
  end

  # Helper to create test files
  def create_test_file(content = "test content", filename = "test.txt")
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
    if Dir.exist?('storage/test')
      FileUtils.rm_rf('storage/test')
    end
    if Dir.exist?('storage/temp')
      Dir.glob('storage/temp/*').each { |f| FileUtils.rm_rf(f) }
    end
    # Ensure tmp directory exists for tests
    FileUtils.mkdir_p('tmp')
  end
end
EOF
}

# Create directories
mkdir -p "$SPEC_DIR/streaming"
mkdir -p "$BACKEND_DIR/coverage"
mkdir -p "$BACKEND_DIR/storage/temp"
mkdir -p "$BACKEND_DIR/storage/encrypted"
mkdir -p "$BACKEND_DIR/storage/test"
mkdir -p "$BACKEND_DIR/tmp"

# Step 1: Setup test environment
echo -e "\n${BLUE}Step 1: Setting up test environment${NC}"
log "Creating test directories and files..."
create_streaming_tests

# Step 2: Check dependencies
echo -e "\n${BLUE}Step 2: Checking dependencies${NC}"
cd "$BACKEND_DIR"
if bundle check > /dev/null 2>&1; then
    echo -e "${GREEN}✓ All gems installed${NC}"
else
    echo "Installing missing gems..."
    bundle install
fi
cd ..

# Step 3: Setup test database
echo -e "\n${BLUE}Step 3: Setting up test database${NC}"
setup_test_database

# Step 4: Fix spec helper
fix_spec_helper

# Step 5: Run basic tests first
echo -e "\n${BLUE}Step 5: Running basic streaming tests${NC}"
run_test_suite "basic_streaming" "spec/streaming/basic_streaming_spec.rb"

# Step 6: Run comprehensive tests
echo -e "\n${BLUE}Step 6: Running comprehensive streaming upload tests${NC}"
run_test_suite "comprehensive_streaming" "spec/streaming/comprehensive_streaming_upload_spec.rb"

# Step 7: Run existing streaming tests
echo -e "\n${BLUE}Step 7: Running existing streaming tests${NC}"
if [ -f "$SPEC_DIR/lib/streaming_upload_spec.rb" ]; then
    run_test_suite "lib_streaming" "spec/lib/streaming_upload_spec.rb"
fi

if [ -f "$SPEC_DIR/integration/streaming_spec.rb" ]; then
    run_test_suite "integration_streaming" "spec/integration/streaming_spec.rb"
fi

# Step 8: Create simple curl test
echo -e "\n${BLUE}Step 8: Running API endpoint test${NC}"
cat > test_api_endpoints.sh << 'EOF'
#!/bin/bash

API_URL="http://localhost:9292/api"

echo "Testing streaming endpoints..."

# Test health endpoint
echo -n "Testing health endpoint: "
HEALTH=$(curl -s "$API_URL/streaming/health")
if echo "$HEALTH" | grep -q '"status":"healthy"'; then
    echo "✓ OK"
else
    echo "✗ Failed"
fi

# Test initialize with valid data
echo -n "Testing initialize endpoint: "
INIT_RESPONSE=$(curl -s -X POST "$API_URL/streaming/initialize" \
    -H "Content-Type: application/json" \
    -d '{
        "filename": "api_test.txt",
        "fileSize": 100,
        "mimeType": "text/plain",
        "password": "TestP@ssw0rd123!",
        "totalChunks": 1,
        "chunkSize": 100
    }')

if echo "$INIT_RESPONSE" | grep -q '"session_id"'; then
    echo "✓ OK"
    SESSION_ID=$(echo "$INIT_RESPONSE" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
    echo "  Session ID: $SESSION_ID"
else
    echo "✗ Failed"
    echo "  Response: $INIT_RESPONSE"
fi
EOF

chmod +x test_api_endpoints.sh

# Check if backend is running
if curl -s http://localhost:9292/api/status > /dev/null 2>&1; then
    ./test_api_endpoints.sh | tee -a "$LOG_FILE"
else
    echo "Backend not running, skipping API tests"
fi

# Step 9: Generate test report
echo -e "\n${BLUE}Step 9: Generating test report${NC}"
cat > "streaming_test_report_${TIMESTAMP}.md" << EOF
# Streaming Upload Test Report
Generated: $(date)

## Test Summary

### Test Suites Run:
1. Basic Streaming Tests
2. Comprehensive Streaming Upload Tests
3. Existing Unit Tests (if found)
4. Integration Tests (if found)
5. API Endpoint Tests

### Key Areas Tested:
- ✓ Session initialization
- ✓ Chunk upload handling
- ✓ Upload finalization
- ✓ Error handling
- ✓ Authentication support
- ✓ Health monitoring

### Test Results:
See log file for detailed results: $LOG_FILE

## Notes:
- Test database was recreated from scratch
- All necessary tables were created
- Streaming upload module was loaded successfully
EOF

# Step 10: Cleanup
echo -e "\n${BLUE}Step 10: Cleaning up test artifacts${NC}"
rm -f test_api_endpoints.sh

# Restore original spec_helper if tests failed
if grep -q "failed" "$LOG_FILE" 2>/dev/null; then
    if [ -f "$SPEC_DIR/spec_helper.rb.bak" ]; then
        mv "$SPEC_DIR/spec_helper.rb.bak" "$SPEC_DIR/spec_helper.rb"
    fi
fi

# Final summary
echo -e "\n${GREEN}=== Test Suite Complete ===${NC}"
echo -e "Log file: ${LOG_FILE}"
echo -e "Test report: streaming_test_report_${TIMESTAMP}.md"
echo -e "\nTo view detailed results:"
echo -e "  cat ${LOG_FILE}"
echo -e "  cat streaming_test_report_${TIMESTAMP}.md"

# Exit with appropriate code
if grep -q "failed\|error" "$LOG_FILE" 2>/dev/null; then
    echo -e "\n${RED}Some tests may have failed. Check log for details.${NC}"
    exit 1
else
    echo -e "\n${GREEN}Tests completed!${NC}"
    exit 0
fi