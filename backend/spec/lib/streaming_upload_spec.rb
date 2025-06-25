# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StreamingUpload do
  let(:test_password) { 'TestP@ssw0rd123!' }
  let(:salt) { Crypto.generate_salt }
  let(:password_hash) { Crypto.hash_password(test_password, salt).to_s }

  describe '.create_session' do
    it 'creates a new upload session' do
      session = StreamingUpload.create_session(
        'test.txt',
        1024 * 1024 * 10, # 10MB
        'text/plain',
        10, # 10 chunks
        1024 * 1024, # 1MB chunks
        password_hash,
        salt
      )

      expect(session[:session_id]).to match(/^[a-f0-9]{32}$/)
      expect(session[:file_id]).to match(/^[a-zA-Z0-9]{8}$/)

      # Check session directory exists
      session_path = File.join(StreamingUpload::TEMP_STORAGE_PATH, session[:session_id])
      expect(Dir.exist?(session_path)).to be true

      # Check metadata file exists
      metadata_file = File.join(session_path, 'metadata.json')
      expect(File.exist?(metadata_file)).to be true
    end
  end

  describe '.store_chunk' do
    let(:session) do
      StreamingUpload.create_session(
        'test.txt', 3 * 1024 * 1024, 'text/plain', 3, 1024 * 1024,
        password_hash, salt
      )
    end

    it 'stores a chunk' do
      chunk_data = 'x' * 1024 * 1024 # 1MB of data
      iv = Base64.strict_encode64(SecureRandom.random_bytes(12))

      result = StreamingUpload.store_chunk(session[:session_id], 0, chunk_data, iv)

      expect(result[:chunks_received]).to eq(1)
      expect(result[:total_chunks]).to eq(3)

      # Check chunk file exists
      session_path = File.join(StreamingUpload::TEMP_STORAGE_PATH, session[:session_id])
      chunk_file = File.join(session_path, 'chunk_0')
      expect(File.exist?(chunk_file)).to be true
      expect(File.size(chunk_file)).to eq(chunk_data.bytesize)
    end

    it 'handles multiple chunks' do
      3.times do |i|
        chunk_data = "chunk_#{i}" * 100_000
        iv = Base64.strict_encode64(SecureRandom.random_bytes(12))

        result = StreamingUpload.store_chunk(session[:session_id], i, chunk_data, iv)
        expect(result[:chunks_received]).to eq(i + 1)
      end
    end
  end

  describe '.finalize_session' do
    let(:session) do
      StreamingUpload.create_session(
        'test.txt', 3 * 100, 'text/plain', 3, 100,
        password_hash, salt
      )
    end

    before do
      # Store all chunks
      3.times do |i|
        chunk_data = "chunk_#{i}" * 10
        iv = Base64.strict_encode64(SecureRandom.random_bytes(12))
        StreamingUpload.store_chunk(session[:session_id], i, chunk_data, iv)
      end
    end

    it 'finalizes the upload' do
      salt_base64 = Base64.strict_encode64(salt)
      file_id = StreamingUpload.finalize_session(session[:session_id], salt_base64)

      expect(file_id).to eq(session[:file_id])

      # Check database record
      file_record = TEST_DB[:encrypted_files].where(file_id: file_id).first
      expect(file_record).not_to be_nil
      expect(file_record[:is_chunked]).to be true
      expect(file_record[:original_filename]).to eq('test.txt')

      # Check session cleaned up
      session_path = File.join(StreamingUpload::TEMP_STORAGE_PATH, session[:session_id])
      expect(Dir.exist?(session_path)).to be false
    end

    it 'fails if chunks are missing' do
      # Create new session with missing chunks
      incomplete_session = StreamingUpload.create_session(
        'incomplete.txt', 5 * 100, 'text/plain', 5, 100,
        password_hash, salt
      )

      # Only store 3 out of 5 chunks
      3.times do |i|
        StreamingUpload.store_chunk(incomplete_session[:session_id], i, 'data', 'iv')
      end

      expect do
        StreamingUpload.finalize_session(incomplete_session[:session_id], salt)
      end.to raise_error(/Missing chunks/)
    end
  end

  describe '.cleanup_old_sessions' do
    it 'removes old sessions' do
      # Create old session
      old_session_id = SecureRandom.hex(16)
      old_session_path = File.join(StreamingUpload::TEMP_STORAGE_PATH, old_session_id)
      FileUtils.mkdir_p(old_session_path)

      # Write old metadata
      metadata = {
        created_at: Time.now.to_i - 7200 # 2 hours ago
      }
      File.write(File.join(old_session_path, 'metadata.json'), metadata.to_json)

      # Create recent session
      recent_session = StreamingUpload.create_session(
        'recent.txt', 100, 'text/plain', 1, 100,
        password_hash, salt
      )

      StreamingUpload.cleanup_old_sessions

      # Old session should be removed
      expect(Dir.exist?(old_session_path)).to be false

      # Recent session should remain
      recent_path = File.join(StreamingUpload::TEMP_STORAGE_PATH, recent_session[:session_id])
      expect(Dir.exist?(recent_path)).to be true
    end
  end
end
