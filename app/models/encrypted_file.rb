class EncryptedFile < ApplicationRecord
  belongs_to :encrypted_payload
  
  # Using the actual columns from the database
  validates :name, presence: true
  validates :content_type, presence: true
  validates :size, presence: true
  
  # Convert file_metadata to JSON before saving if it's a Hash
  before_save :ensure_file_metadata_is_json
  
  private
  
  def ensure_file_metadata_is_json
    if file_metadata.is_a?(Hash)
      self.file_metadata = file_metadata.to_json
    end
  end
end
