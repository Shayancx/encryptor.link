class EncryptedPayloadService
  def self.create_with_files(payload_text, files_data)
    EncryptedPayload.transaction do
      payload = EncryptedPayload.create!(payload: payload_text || "")
      
      (files_data || []).each do |file_data|
        encrypted_file = payload.encrypted_files.build(
          file_id: file_data[:file_id] || SecureRandom.uuid,
          encrypted_file: file_data[:encrypted_file],
          content_type: file_data[:content_type],
          size: file_data[:size] || 0
        )
        encrypted_file.save!
      end
      
      payload
    end
  end
  
  def self.find_with_files(id)
    payload = EncryptedPayload.find_by(id: id)
    return nil unless payload
    
    {
      payload: payload.payload,
      files: payload.encrypted_files.map do |file|
        {
          id: file.file_id,
          content_type: file.content_type,
          size: file.size,
          encrypted_content: file.encrypted_file
        }
      end
    }
  end
end
