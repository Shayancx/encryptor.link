# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Streaming Upload Edge Cases' do
  include Rack::Test::Methods
  include ApiHelper

  let(:test_password) { 'TestP@ssw0rd123!' }
  let(:salt) { Crypto.generate_salt }

  describe 'Network Failure Simulation' do
    it 'handles partial chunk uploads' do
      session = StreamingUpload.create_session(
        'network_test.txt',
        2048,
        'text/plain',
        2,
        1024,
        Crypto.hash_password(test_password, salt).to_s,
        salt
      )

      # Upload first chunk successfully
      post '/api/streaming/chunk', {
        session_id: session[:session_id],
        chunk_index: '0',
        iv: Base64.strict_encode64(SecureRandom.random_bytes(12)),
        chunk_data: Rack::Test::UploadedFile.new(StringIO.new('chunk0'), 'text/plain')
      }

      expect(last_response.status).to eq(200)

      # Session should still exist after partial upload
      session_path = File.join(StreamingUpload::TEMP_STORAGE_PATH, session[:session_id])
      expect(Dir.exist?(session_path)).to be true

      # Should be able to resume
      post '/api/streaming/chunk', {
        session_id: session[:session_id],
        chunk_index: '1',
        iv: Base64.strict_encode64(SecureRandom.random_bytes(12)),
        chunk_data: Rack::Test::UploadedFile.new(StringIO.new('chunk1'), 'text/plain')
      }

      expect(last_response.status).to eq(200)
    end
  end

  describe 'Boundary Conditions' do
    it 'handles empty files' do
      post '/api/streaming/initialize', {
        filename: 'empty.txt',
        fileSize: 0,
        mimeType: 'text/plain',
        password: test_password,
        totalChunks: 0,
        chunkSize: 1024
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      # Should handle gracefully (implementation-dependent behavior)
      expect([200, 400]).to include(last_response.status)
    end

    it 'handles exactly chunk-sized files' do
      chunk_size = 1024 * 1024

      post '/api/streaming/initialize', {
        filename: 'exact_chunk.bin',
        fileSize: chunk_size,
        mimeType: 'application/octet-stream',
        password: test_password,
        totalChunks: 1,
        chunkSize: chunk_size
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
    end

    it 'handles one-byte-over chunk size' do
      chunk_size = 1024 * 1024
      file_size = chunk_size + 1

      post '/api/streaming/initialize', {
        filename: 'over_by_one.bin',
        fileSize: file_size,
        mimeType: 'application/octet-stream',
        password: test_password,
        totalChunks: 2,
        chunkSize: chunk_size
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      data = JSON.parse(last_response.body)

      # Should create session for 2 chunks
      session_id = data['session_id']

      # Upload first chunk (full size)
      post '/api/streaming/chunk', {
        session_id: session_id,
        chunk_index: '0',
        iv: Base64.strict_encode64(SecureRandom.random_bytes(12)),
        chunk_data: Rack::Test::UploadedFile.new(
          StringIO.new('x' * chunk_size),
          'application/octet-stream'
        )
      }

      expect(last_response.status).to eq(200)

      # Upload second chunk (1 byte)
      post '/api/streaming/chunk', {
        session_id: session_id,
        chunk_index: '1',
        iv: Base64.strict_encode64(SecureRandom.random_bytes(12)),
        chunk_data: Rack::Test::UploadedFile.new(
          StringIO.new('x'),
          'application/octet-stream'
        )
      }

      expect(last_response.status).to eq(200)
    end
  end

  describe 'Security Edge Cases' do
    it 'prevents path traversal in session IDs' do
      malicious_session_id = '../../../etc/passwd'

      post '/api/streaming/chunk', {
        session_id: malicious_session_id,
        chunk_index: '0',
        iv: Base64.strict_encode64(SecureRandom.random_bytes(12)),
        chunk_data: Rack::Test::UploadedFile.new(StringIO.new('data'), 'text/plain')
      }

      expect(last_response.status).to eq(500)

      # Ensure no file was created outside temp directory
      expect(File.exist?('/etc/passwd.chunk_0')).to be false
    end

    it 'handles extremely long filenames' do
      long_filename = "#{'a' * 500}.txt"

      post '/api/streaming/initialize', {
        filename: long_filename,
        fileSize: 100,
        mimeType: 'text/plain',
        password: test_password,
        totalChunks: 1,
        chunkSize: 100
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      # Should either succeed or fail gracefully
      expect([200, 400]).to include(last_response.status)
    end
  end

  describe 'Race Conditions' do
    it 'handles simultaneous chunk uploads to same session' do
      session = StreamingUpload.create_session(
        'race_test.txt',
        3072,
        'text/plain',
        3,
        1024,
        Crypto.hash_password(test_password, salt).to_s,
        salt
      )

      threads = []
      results = []
      mutex = Mutex.new

      # Upload same chunks from multiple threads
      3.times do |i|
        2.times do |j|
          threads << Thread.new do
            response = post '/api/streaming/chunk', {
              session_id: session[:session_id],
              chunk_index: i.to_s,
              iv: Base64.strict_encode64(SecureRandom.random_bytes(12)),
              chunk_data: Rack::Test::UploadedFile.new(
                StringIO.new("chunk_#{i}_thread_#{j}"),
                'text/plain'
              )
            }

            mutex.synchronize do
              results << {
                chunk: i,
                thread: j,
                status: response.status,
                body: JSON.parse(response.body)
              }
            end
          end
        end
      end

      threads.each(&:join)

      # All requests should complete without error
      results.each do |result|
        expect(result[:status]).to eq(200)
      end

      # Should have exactly 3 chunks received
      final_result = results.last[:body]
      expect(final_result['chunks_received']).to eq(3)
    end
  end
end
