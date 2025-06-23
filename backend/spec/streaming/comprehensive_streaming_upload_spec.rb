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
