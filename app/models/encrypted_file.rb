class EncryptedFile < ApplicationRecord
  belongs_to :encrypted_payload
  belongs_to :message, optional: true
  
  # Use Active Storage for the encrypted file
  has_one_attached :encrypted_blob
  
  # Validation using actual column names
  validates :file_name, presence: true
  validates :file_type, presence: true
  validates :file_size, presence: true, numericality: { less_than_or_equal_to: 1000.megabytes }
  
  # Alias for compatibility
  alias_attribute :content_type, :file_type
  alias_attribute :size, :file_size
  alias_attribute :name, :file_name
  
  # Ensure file_metadata is properly handled
  before_save :ensure_file_metadata_is_json
  
  # Store encrypted data as a file
  def store_encrypted_data(base64_data)
    # Convert base64 to binary data
    binary_data = Base64.decode64(base64_data)
    
    # Create a temp file
    temp_file = Tempfile.new(['encrypted', '.enc'])
    temp_file.binmode
    temp_file.write(binary_data)
    temp_file.rewind
    
    # Attach to Active Storage
    self.encrypted_blob.attach(
      io: temp_file,
      filename: "#{SecureRandom.hex(16)}.enc",
      content_type: 'application/octet-stream'
    )
    
    # Store the blob key for quick access
    self.encrypted_blob_key = self.encrypted_blob.key if self.encrypted_blob.attached?
    
    temp_file.close
    temp_file.unlink
  end
  
  # Retrieve encrypted data
  def get_encrypted_data
    return nil unless encrypted_blob.attached?
    
    # Read the file and return as base64
    Base64.encode64(encrypted_blob.download)
  end
  
  private
  
  def ensure_file_metadata_is_json
    if file_metadata.is_a?(Hash)
      self.file_metadata = file_metadata.to_json
    end
  end
end
