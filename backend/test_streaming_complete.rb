#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require_relative 'app'

puts '🧪 Testing Complete Streaming Upload Setup...'
puts '==========================================='

# Test 1: Module loading
puts "\n1. Testing module loading..."
begin
  require_relative 'lib/crypto'
  require_relative 'lib/file_storage'
  require_relative 'lib/streaming_upload'
  puts '✓ All modules loaded successfully'
rescue StandardError => e
  puts "✗ Module loading failed: #{e.message}"
  exit 1
end

# Test 2: Create test session
puts "\n2. Testing session creation..."
begin
  password = 'TestP@ssw0rd123!'
  salt = Crypto.generate_salt
  hash = Crypto.hash_password(password, salt)

  session = StreamingUpload.create_session(
    'test.txt',
    1024 * 1024, # 1MB
    'text/plain',
    1, # 1 chunk
    1024 * 1024,
    hash.to_s,
    salt
  )

  puts "✓ Session created: #{session[:session_id]}"
  puts "  File ID: #{session[:file_id]}"

  # Test 3: Store a chunk
  puts "\n3. Testing chunk storage..."
  test_data = 'x' * 1000
  iv = Base64.strict_encode64(SecureRandom.random_bytes(12))

  result = StreamingUpload.store_chunk(session[:session_id], 0, test_data, iv)
  puts "✓ Chunk stored: #{result[:chunks_received]}/#{result[:total_chunks]}"

  # Test 4: Finalize
  puts "\n4. Testing finalization..."
  file_id = StreamingUpload.finalize_session(session[:session_id], Base64.strict_encode64(salt))
  puts "✓ Upload finalized: #{file_id}"

  # Cleanup
  file_record = DB[:encrypted_files].where(file_id: file_id).first
  if file_record
    FileStorage.delete_file(file_record[:file_path])
    DB[:encrypted_files].where(file_id: file_id).delete
  end

  puts "\n✅ All tests passed!"
rescue StandardError => e
  puts "✗ Test failed: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end
