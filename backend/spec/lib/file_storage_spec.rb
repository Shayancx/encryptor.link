# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FileStorage do
  before(:all) do
    FileStorage.initialize_storage
  end

  describe '.initialize_storage' do
    it 'creates storage directory' do
      expect(Dir.exist?(FileStorage::STORAGE_PATH)).to be true
    end
  end

  describe '.validate_file' do
    context 'with size validation' do
      it 'accepts files under the limit' do
        result = FileStorage.validate_file('x' * 1000, 'text/plain', 10_000)
        expect(result[:valid]).to be true
      end

      it 'rejects files over the limit' do
        result = FileStorage.validate_file('x' * 10_001, 'text/plain', 10_000)
        expect(result[:valid]).to be false
        expect(result[:error]).to include('too large')
      end

      it 'rejects files over absolute maximum' do
        huge_data = 'x' * (FileStorage::MAX_FILE_SIZE_ABSOLUTE + 1)
        result = FileStorage.validate_file(huge_data, 'text/plain', FileStorage::MAX_FILE_SIZE_ABSOLUTE + 1000)
        expect(result[:valid]).to be false
        expect(result[:error]).to include('absolute maximum')
      end
    end

    context 'with different limits' do
      it 'validates against anonymous limit' do
        data = 'x' * (FileStorage::MAX_FILE_SIZE_ANONYMOUS - 1)
        result = FileStorage.validate_file(data, 'text/plain', FileStorage::MAX_FILE_SIZE_ANONYMOUS)
        expect(result[:valid]).to be true
      end

      it 'validates against authenticated limit' do
        data = 'x' * 1_000_000 # 1MB
        result = FileStorage.validate_file(data, 'text/plain', FileStorage::MAX_FILE_SIZE_AUTHENTICATED)
        expect(result[:valid]).to be true
      end
    end

    it 'accepts all MIME types' do
      mime_types = [
        'text/plain',
        'application/pdf',
        'image/jpeg',
        'audio/mpeg',
        'video/mp4',
        'application/octet-stream',
        'application/x-custom-type'
      ]

      mime_types.each do |mime|
        result = FileStorage.validate_file('test', mime, 1000)
        expect(result[:valid]).to eq(true), "MIME type #{mime} should be accepted but got: #{result[:error]}"
      end
    end
  end

  describe '.generate_file_path' do
    it 'creates subdirectories based on file ID' do
      file_id = 'abcd1234'
      path = FileStorage.generate_file_path(file_id)

      expect(path).to include('/ab/abcd1234.enc')
      expect(Dir.exist?(File.dirname(path))).to be true
    end

    it 'handles edge case file IDs' do
      edge_cases = %w[a ab 12345678 UPPERCASE]

      edge_cases.each do |file_id|
        expect { FileStorage.generate_file_path(file_id) }.not_to raise_error
      end
    end
  end

  describe '.store_encrypted_file' do
    let(:file_id) { Crypto.generate_file_id }
    let(:data) { 'encrypted content' }

    after do
      path = FileStorage.generate_file_path(file_id)
      FileStorage.delete_file(path)
    end

    it 'stores encrypted data' do
      path = FileStorage.store_encrypted_file(file_id, data)

      expect(File.exist?(path)).to be true
      expect(File.read(path, mode: 'rb')).to eq(data)
    end

    it 'raises error if file already exists' do
      FileStorage.store_encrypted_file(file_id, data)

      expect do
        FileStorage.store_encrypted_file(file_id, 'new data')
      end.to raise_error('File already exists')
    end

    it 'creates necessary subdirectories' do
      path = FileStorage.store_encrypted_file(file_id, data)
      expect(Dir.exist?(File.dirname(path))).to be true
    end

    it 'stores binary data correctly' do
      binary_data = SecureRandom.random_bytes(1024)
      path = FileStorage.store_encrypted_file(file_id, binary_data)

      read_data = File.read(path, mode: 'rb')
      expect(read_data.encoding).to eq(Encoding::ASCII_8BIT)
      expect(read_data).to eq(binary_data)
    end
  end

  describe '.read_encrypted_file' do
    let(:file_id) { Crypto.generate_file_id }
    let(:data) { 'test encrypted data' }
    let(:file_path) { FileStorage.store_encrypted_file(file_id, data) }

    after { FileStorage.delete_file(file_path) }

    it 'reads stored data' do
      read_data = FileStorage.read_encrypted_file(file_path)
      expect(read_data).to eq(data)
    end

    it 'returns nil for non-existent files' do
      read_data = FileStorage.read_encrypted_file('/non/existent/path')
      expect(read_data).to be_nil
    end

    it 'reads binary data correctly' do
      binary_data = SecureRandom.random_bytes(1024)
      binary_path = FileStorage.store_encrypted_file('binary123', binary_data)

      read_data = FileStorage.read_encrypted_file(binary_path)
      expect(read_data).to eq(binary_data)

      FileStorage.delete_file(binary_path)
    end
  end

  describe '.delete_file' do
    let(:file_id) { Crypto.generate_file_id }
    let(:file_path) { FileStorage.store_encrypted_file(file_id, 'data') }

    it 'deletes the file' do
      expect(File.exist?(file_path)).to be true

      FileStorage.delete_file(file_path)

      expect(File.exist?(file_path)).to be false
    end

    it 'removes empty directories' do
      dir = File.dirname(file_path)
      FileStorage.delete_file(file_path)

      expect(Dir.exist?(dir)).to be false
    end

    it 'handles non-existent files gracefully' do
      expect do
        FileStorage.delete_file('/non/existent/file')
      end.not_to raise_error
    end

    it 'does not remove non-empty directories' do
      # Create another file in same directory
      another_id = "#{file_id[0..1]}other"
      another_path = FileStorage.store_encrypted_file(another_id, 'data')

      FileStorage.delete_file(file_path)

      expect(Dir.exist?(File.dirname(file_path))).to be true

      FileStorage.delete_file(another_path)
    end
  end

  describe '.cleanup_expired_files' do
    let(:db) { TEST_DB }

    before do
      # Create test data directly in database
      @expired_id = db[:encrypted_files].insert(
        file_id: 'expired01',
        password_hash: 'hash',
        salt: 'salt',
        file_path: FileStorage.store_encrypted_file('expired01', 'data'),
        original_filename: 'test.txt',
        mime_type: 'text/plain',
        file_size: 4,
        encryption_iv: 'iv',
        created_at: Time.now - 7200,
        expires_at: Time.now - 3600,
        ip_address: '127.0.0.1'
      )

      @active_id = db[:encrypted_files].insert(
        file_id: 'active001',
        password_hash: 'hash',
        salt: 'salt',
        file_path: FileStorage.store_encrypted_file('active001', 'data'),
        original_filename: 'test.txt',
        mime_type: 'text/plain',
        file_size: 4,
        encryption_iv: 'iv',
        created_at: Time.now,
        expires_at: Time.now + 3600,
        ip_address: '127.0.0.1'
      )
    end

    after do
      # Clean up
      begin
        FileStorage.delete_file(FileStorage.generate_file_path('expired01'))
      rescue StandardError
        nil
      end
      begin
        FileStorage.delete_file(FileStorage.generate_file_path('active001'))
      rescue StandardError
        nil
      end
    end

    it 'deletes expired files from storage' do
      expired_path = db[:encrypted_files].where(id: @expired_id).first[:file_path]
      active_path = db[:encrypted_files].where(id: @active_id).first[:file_path]

      FileStorage.cleanup_expired_files(db)

      expect(File.exist?(expired_path)).to be false
      expect(File.exist?(active_path)).to be true
    end

    it 'removes expired records from database' do
      FileStorage.cleanup_expired_files(db)

      expect(db[:encrypted_files].where(id: @expired_id).count).to eq(0)
      expect(db[:encrypted_files].where(id: @active_id).count).to eq(1)
    end

    it 'handles missing files gracefully' do
      # Delete file manually
      expired_record = db[:encrypted_files].where(id: @expired_id).first
      File.delete(expired_record[:file_path]) if File.exist?(expired_record[:file_path])

      expect do
        FileStorage.cleanup_expired_files(db)
      end.not_to raise_error
    end
  end

  describe '.upload_limit_for_user' do
    it 'returns anonymous limit for non-authenticated users' do
      limit = FileStorage.upload_limit_for_user(false)
      expect(limit).to eq(FileStorage::MAX_FILE_SIZE_ANONYMOUS)
    end

    it 'returns authenticated limit for authenticated users' do
      limit = FileStorage.upload_limit_for_user(true)
      expect(limit).to eq(FileStorage::MAX_FILE_SIZE_AUTHENTICATED)
    end
  end
end
