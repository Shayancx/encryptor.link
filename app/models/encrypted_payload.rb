class EncryptedPayload < ApplicationRecord
  has_many :encrypted_files, dependent: :destroy
  
  validates :ciphertext, presence: true
  
  # Method to create payload with proper parameter mapping
  def self.create_with_files(request_params)
    encrypted_data = request_params.dig(:data, :encrypted_data)
    metadata = request_params.dig(:data, :metadata) || {}
    files_data = metadata[:files] || []
    
    ActiveRecord::Base.transaction do
      # Create the payload with ciphertext column
      payload = self.create!(
        ciphertext: encrypted_data, # Map encrypted_data to ciphertext
        expires_at: metadata[:expires_at],
        max_views: metadata[:max_views],
        burn_after_reading: metadata[:burn_after_reading],
        password_digest: metadata[:has_password] ? "password_protected" : nil
      )
      
      # Create associated files
      files_data.each do |file_data|
        file_metadata = file_data[:metadata] || {}
        
        payload.encrypted_files.create!(
          name: file_data[:name],
          content_type: file_data[:type],
          size: file_data[:size],
          file_metadata: file_metadata.to_json
        )
      end
      
      return payload
    end
  rescue StandardError => e
    Rails.logger.error("Failed to create encrypted payload with files: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise e
  end
end
