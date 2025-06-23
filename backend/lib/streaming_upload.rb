require 'securerandom'
require 'json'
require 'fileutils'
require 'thread'
require 'digest'

module StreamingUpload
  TEMP_STORAGE_PATH = File.expand_path('../storage/temp', __dir__)
  
  # Thread-safe session storage
  @sessions = {}
  @session_mutex = Mutex.new
  
  class << self
    def initialize_storage
      FileUtils.mkdir_p(TEMP_STORAGE_PATH)
      FileUtils.mkdir_p(File.expand_path('../storage/encrypted', __dir__))
      LOGGER.info "StreamingUpload storage initialized"
    end
    
    def create_session(filename, file_size, mime_type, total_chunks, chunk_size, password_hash, salt, account_id = nil)
      session_id = SecureRandom.hex(16)
      file_id = Crypto.generate_file_id
      
      session_path = File.join(TEMP_STORAGE_PATH, session_id)
      FileUtils.mkdir_p(session_path)
      
      metadata = {
        session_id: session_id,
        file_id: file_id,
        filename: filename,
        file_size: file_size,
        mime_type: mime_type,
        total_chunks: total_chunks,
        chunk_size: chunk_size,
        password_hash: password_hash,
        salt: salt,
        account_id: account_id,
        created_at: Time.now.to_i,
        chunks_received: []
      }
      
      # Write metadata
      metadata_file = File.join(session_path, 'metadata.json')
      File.write(metadata_file, metadata.to_json)
      
      LOGGER.info "Session created: #{session_id} for file: #{filename} (#{total_chunks} chunks)"
      
      {
        session_id: session_id,
        file_id: file_id
      }
    rescue => e
      FileUtils.rm_rf(session_path) if session_path && Dir.exist?(session_path)
      LOGGER.error "Failed to create session: #{e.message}"
      raise e
    end
    
    def store_chunk(session_id, chunk_index, chunk_data, iv)
      session_path = File.join(TEMP_STORAGE_PATH, session_id)
      
      unless File.exist?(session_path)
        raise "Invalid session: #{session_id}"
      end
      
      metadata_file = File.join(session_path, 'metadata.json')
      
      # Use file locking to prevent race conditions
      File.open(metadata_file, 'r+') do |file|
        file.flock(File::LOCK_EX)
        
        # Read current metadata
        metadata = JSON.parse(file.read)
        
        # Validate chunk index
        chunk_index = chunk_index.to_i
        if chunk_index < 0 || chunk_index >= metadata['total_chunks']
          raise "Invalid chunk index: #{chunk_index} (expected 0-#{metadata['total_chunks'] - 1})"
        end
        
        # Check if already received
        if metadata['chunks_received'].include?(chunk_index)
          LOGGER.info "Chunk #{chunk_index} already received for session #{session_id}"
          return {
            chunks_received: metadata['chunks_received'].length,
            total_chunks: metadata['total_chunks'],
            duplicate: true
          }
        end
        
        # Store chunk
        chunk_file = File.join(session_path, "chunk_#{chunk_index}")
        
        # Ensure chunk data is binary
        if chunk_data.respond_to?(:force_encoding)
          chunk_data = chunk_data.force_encoding('BINARY')
        end
        
        # Write chunk atomically
        temp_chunk = "#{chunk_file}.tmp"
        File.open(temp_chunk, 'wb') do |f|
          f.write(chunk_data)
          f.fsync
        end
        File.rename(temp_chunk, chunk_file)
        
        # Store IV
        File.write("#{chunk_file}.iv", iv)
        
        # Update metadata
        metadata['chunks_received'] << chunk_index
        metadata['chunks_received'].sort!
        
        # Write updated metadata
        file.rewind
        file.truncate(0)
        file.write(metadata.to_json)
        file.fsync
      end
      
      # Read updated metadata for response
      updated_metadata = JSON.parse(File.read(metadata_file))
      
      LOGGER.info "Chunk #{chunk_index} stored for session #{session_id}: #{chunk_data.bytesize} bytes"
      
      {
        chunks_received: updated_metadata['chunks_received'].length,
        total_chunks: updated_metadata['total_chunks']
      }
    rescue => e
      LOGGER.error "Error storing chunk #{chunk_index} for session #{session_id}: #{e.message}"
      LOGGER.error e.backtrace.first(5).join("\n")
      raise e
    end
    
    def finalize_session(session_id, salt)
      session_path = File.join(TEMP_STORAGE_PATH, session_id)
      metadata_file = File.join(session_path, 'metadata.json')
      
      unless File.exist?(metadata_file)
        raise "Session not found: #{session_id}"
      end
      
      metadata = JSON.parse(File.read(metadata_file))
      
      # Verify all chunks received
      expected_chunks = (0...metadata['total_chunks']).to_a
      received_chunks = metadata['chunks_received'].sort
      
      if received_chunks != expected_chunks
        missing = expected_chunks - received_chunks
        raise "Missing chunks: #{missing.join(', ')} (received: #{received_chunks.length}/#{metadata['total_chunks']})"
      end
      
      # Verify chunk files exist
      metadata['total_chunks'].times do |i|
        chunk_file = File.join(session_path, "chunk_#{i}")
        unless File.exist?(chunk_file) && File.size(chunk_file) > 0
          raise "Chunk file missing or empty: #{i}"
        end
      end
      
      # Combine chunks
      file_id = metadata['file_id']
      final_path = FileStorage.generate_file_path(file_id)
      FileUtils.mkdir_p(File.dirname(final_path))
      
      LOGGER.info "Combining #{metadata['total_chunks']} chunks into #{final_path}"
      
      File.open(final_path, 'wb') do |output|
        # Write header
        header = {
          version: 2,
          total_chunks: metadata['total_chunks'],
          chunk_size: metadata['chunk_size'],
          salt: salt
        }
        header_json = header.to_json
        output.write([header_json.bytesize].pack('N'))
        output.write(header_json)
        
        # Write chunks
        metadata['total_chunks'].times do |i|
          chunk_file = File.join(session_path, "chunk_#{i}")
          iv_file = File.join(session_path, "chunk_#{i}.iv")
          
          chunk_data = File.read(chunk_file, mode: 'rb')
          iv_data = File.read(iv_file)
          
          output.write([iv_data.bytesize].pack('N'))
          output.write(iv_data)
          output.write([chunk_data.bytesize].pack('N'))
          output.write(chunk_data)
        end
        
        output.fsync
      end
      
      # Store in database
      expires_at = Time.now + (24 * 3600)
      
      DB[:encrypted_files].insert(
        file_id: file_id,
        password_hash: metadata['password_hash'],
        salt: metadata['salt'],
        file_path: final_path,
        original_filename: metadata['filename'],
        mime_type: metadata['mime_type'],
        file_size: metadata['file_size'],
        encryption_iv: '',
        created_at: Time.now,
        expires_at: expires_at,
        ip_address: '127.0.0.1',
        account_id: metadata['account_id'],
        is_chunked: true
      )
      
      LOGGER.info "File stored: #{file_id} (#{metadata['filename']})"
      
      # Clean up
      FileUtils.rm_rf(session_path)
      
      file_id
    rescue => e
      LOGGER.error "Error finalizing session #{session_id}: #{e.message}"
      LOGGER.error e.backtrace.first(5).join("\n")
      raise e
    end
    
    def cleanup_old_sessions
      return unless Dir.exist?(TEMP_STORAGE_PATH)
      
      Dir.glob(File.join(TEMP_STORAGE_PATH, '*')).each do |session_path|
        next unless File.directory?(session_path)
        
        metadata_file = File.join(session_path, 'metadata.json')
        next unless File.exist?(metadata_file)
        
        begin
          metadata = JSON.parse(File.read(metadata_file))
          
          # Remove sessions older than 1 hour
          if Time.now.to_i - metadata['created_at'] > 3600
            LOGGER.info "Cleaning up old session: #{File.basename(session_path)}"
            FileUtils.rm_rf(session_path)
          end
        rescue => e
          LOGGER.error "Removing corrupted session: #{e.message}"
          FileUtils.rm_rf(session_path)
        end
      end
    end
    
    def get_file_info(file_id)
      file_record = DB[:encrypted_files].where(file_id: file_id).first
      
      unless file_record
        raise "File not found: #{file_id}"
      end
      
      unless file_record[:is_chunked]
        raise "File is not chunked"
      end
      
      File.open(file_record[:file_path], 'rb') do |f|
        header_size = f.read(4).unpack('N')[0]
        header = JSON.parse(f.read(header_size))
        
        {
          filename: file_record[:original_filename],
          mime_type: file_record[:mime_type],
          file_size: file_record[:file_size],
          total_chunks: header['total_chunks'],
          chunk_size: header['chunk_size'],
          salt: header['salt']
        }
      end
    end
    
    def read_chunk(file_id, chunk_index, password)
      file_record = DB[:encrypted_files].where(file_id: file_id).first
      
      unless file_record
        raise "File not found: #{file_id}"
      end
      
      unless Crypto.verify_password(password, file_record[:salt], file_record[:password_hash])
        raise "Invalid password"
      end
      
      unless file_record[:is_chunked]
        raise "File is not chunked"
      end
      
      File.open(file_record[:file_path], 'rb') do |f|
        header_size = f.read(4).unpack('N')[0]
        header = JSON.parse(f.read(header_size))
        
        if chunk_index >= header['total_chunks']
          raise "Chunk index out of range"
        end
        
        # Skip to requested chunk
        chunk_index.times do
          iv_size = f.read(4).unpack('N')[0]
          f.seek(iv_size, IO::SEEK_CUR)
          chunk_size = f.read(4).unpack('N')[0]
          f.seek(chunk_size, IO::SEEK_CUR)
        end
        
        # Read chunk
        iv_size = f.read(4).unpack('N')[0]
        iv = f.read(iv_size)
        chunk_size = f.read(4).unpack('N')[0]
        chunk_data = f.read(chunk_size)
        
        {
          data: Base64.strict_encode64(chunk_data),
          iv: iv,
          salt: header['salt']
        }
      end
    end
  end
end

# Initialize storage
StreamingUpload.initialize_storage

# Start cleanup thread
Thread.new do
  loop do
    begin
      StreamingUpload.cleanup_old_sessions
    rescue => e
      puts "Cleanup error: #{e.message}"
    end
    sleep 300
  end
end
