# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Streaming Upload Endpoints' do
  include Rack::Test::Methods
  include ApiHelper

  let(:test_file_content) { 'x' * (2 * 1024 * 1024) } # 2MB test file
  let(:chunk_size) { 1024 * 1024 } # 1MB chunks
  let(:total_chunks) { 2 }
  let(:strong_password) { 'TestP@ssw0rd123!' }

  describe 'POST /api/streaming/initialize' do
    it 'initializes a streaming upload session' do
      post '/api/streaming/initialize', {
        filename: 'test-large.bin',
        fileSize: test_file_content.length,
        mimeType: 'application/octet-stream',
        totalChunks: total_chunks,
        chunkSize: chunk_size,
        password: strong_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(json_response).to have_key('session_id')
      expect(json_response).to have_key('file_id')
      expect(json_response['session_id']).to match(/^[a-f0-9]{32}$/)
      expect(json_response['file_id']).to match(/^[a-zA-Z0-9]{8}$/)
    end

    it 'rejects weak passwords' do
      post '/api/streaming/initialize', {
        filename: 'test.bin',
        fileSize: 1000,
        mimeType: 'application/octet-stream',
        totalChunks: 1,
        chunkSize: 1000,
        password: 'weak'
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      expect(json_response['error']).to include('characters')
    end

    it 'enforces file size limits for anonymous users' do
      large_size = 200 * 1024 * 1024 # 200MB

      post '/api/streaming/initialize', {
        filename: 'huge.bin',
        fileSize: large_size,
        mimeType: 'application/octet-stream',
        totalChunks: 200,
        chunkSize: chunk_size,
        password: strong_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      expect(json_response['error']).to include('too large')
    end
  end

  describe 'Complete streaming upload flow' do
    it 'uploads file in chunks and finalizes' do
      # Step 1: Initialize session
      post '/api/streaming/initialize', {
        filename: 'test-stream.bin',
        fileSize: test_file_content.length,
        mimeType: 'application/octet-stream',
        totalChunks: total_chunks,
        chunkSize: chunk_size,
        password: strong_password
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      session_id = json_response['session_id']
      file_id = json_response['file_id']

      # Step 2: Upload chunks
      salt = Crypto.generate_salt

      total_chunks.times do |i|
        chunk_start = i * chunk_size
        chunk_end = [chunk_start + chunk_size, test_file_content.length].min
        chunk_data = test_file_content[chunk_start...chunk_end]

        # Encrypt chunk
        iv = Base64.strict_encode64(SecureRandom.random_bytes(12))
        key = Crypto.derive_key(strong_password, salt)
        cipher = OpenSSL::Cipher.new('AES-256-GCM')
        cipher.encrypt
        cipher.key = key
        cipher.iv = Base64.strict_decode64(iv)
        encrypted_chunk = cipher.update(chunk_data) + cipher.final

        # Upload chunk
        post '/api/streaming/chunk', {
          session_id: session_id,
          chunk_index: i,
          chunk_data: Rack::Test::UploadedFile.new(StringIO.new(encrypted_chunk), 'application/octet-stream'),
          iv: iv
        }

        expect(last_response.status).to eq(200)
        expect(json_response['chunks_received']).to eq(i + 1)
      end

      # Step 3: Finalize upload
      post '/api/streaming/finalize', {
        session_id: session_id,
        salt: Base64.strict_encode64(salt)
      }.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(json_response['file_id']).to eq(file_id)

      # Verify file exists in database
      file_record = TEST_DB[:encrypted_files].where(file_id: file_id).first
      expect(file_record).not_to be_nil
      expect(file_record[:is_chunked]).to be true
      expect(file_record[:original_filename]).to eq('test-stream.bin')
    end
  end

  describe 'GET /api/streaming/info/:file_id' do
    let(:file_id) do
      # Create a chunked file first
      session = StreamingUpload.create_session(
        'info-test.bin',
        1024,
        'application/octet-stream',
        1,
        1024,
        Crypto.hash_password(strong_password, 'salt').to_s,
        'salt'
      )

      StreamingUpload.store_chunk(session[:session_id], 0, 'data', 'iv')
      StreamingUpload.finalize_session(session[:session_id], Base64.strict_encode64('salt'))
    end

    it 'returns file info for chunked files' do
      get "/api/streaming/info/#{file_id}"

      expect(last_response.status).to eq(200)
      expect(json_response).to have_key('filename')
      expect(json_response).to have_key('total_chunks')
      expect(json_response).to have_key('chunk_size')
    end

    it 'returns 404 for non-existent files' do
      get '/api/streaming/info/notexist'

      expect(last_response.status).to eq(404)
    end
  end
end
