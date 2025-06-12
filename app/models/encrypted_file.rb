class EncryptedFile < ApplicationRecord
  belongs_to :encrypted_payload
  belongs_to :message, optional: true
  
  # Use Active Storage for the encrypted file
  has_one_attached :encrypted_blob
  
  # Validation using actual column names
  validates :file_name, presence: true
  validates :file_type, presence: true
  validates :file_size, presence: true, numericality: { less_than_or_equal_to: 1000.megabytes }
  
  # Ensure file_metadata is properly handled
  before_save :ensure_file_metadata_is_json
  
  # Store encrypted data as a file with improved error handling
  def store_encrypted_data(base64_data)
    begin
      Rails.logger.info "Storing encrypted data for file: #{file_name}"
      
      # Validate base64 format
      unless base64_data.is_a?(String) && base64_data.match?(/\A[A-Za-z0-9+\/]*={0,2}\z/)
        raise StandardError, "Invalid base64 format for file: #{file_name}"
      end
      
      # Convert base64 to binary data
      binary_data = Base64.decode64(base64_data)
      
      # Create a StringIO instead of a temp file to avoid the closed stream issue
      io = StringIO.new(binary_data)
      io.rewind
      
      # Attach to Active Storage
      begin
        self.encrypted_blob.attach(
          io: io,
          filename: "#{SecureRandom.hex(16)}.enc",
          content_type: 'application/octet-stream'
        )
        
        Rails.logger.info "Successfully attached blob for file: #{file_name}"
      rescue => attachment_error
        Rails.logger.error "Active Storage attachment failed: #{attachment_error.message}"
        raise StandardError, "Failed to store encrypted file: #{attachment_error.message}"
      ensure
        io.close if io && !io.closed?
      end
      
      # Store the blob key for quick access
      if self.encrypted_blob.attached?
        self.encrypted_blob_key = self.encrypted_blob.key
        Rails.logger.info "Stored blob key: #{self.encrypted_blob_key}"
      else
        raise StandardError, "Blob attachment failed for file: #{file_name}"
      end
      
    rescue => e
      Rails.logger.error "Error storing encrypted file data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
  
  # Retrieve encrypted data
  def get_encrypted_data
    return nil unless encrypted_blob.attached?
    
    # Read the file and return as base64
    Base64.encode64(encrypted_blob.download)
  rescue => e
    Rails.logger.error "Error retrieving encrypted data: #{e.message}"
    nil
  end
  
  private
  
  def ensure_file_metadata_is_json
    if file_metadata.is_a?(Hash)
      self.file_metadata = file_metadata.to_json
    end
  end
end
