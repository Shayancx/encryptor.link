class FixEncryptedPayloadsAndFiles < ActiveRecord::Migration[8.0]
  def change
    # Ensure max_views column exists with proper default
    unless column_exists?(:encrypted_payloads, :max_views)
      add_column :encrypted_payloads, :max_views, :integer
    end
    
    # Ensure encrypted_blob_key exists for encrypted_files
    unless column_exists?(:encrypted_files, :encrypted_blob_key)
      add_column :encrypted_files, :encrypted_blob_key, :string
      add_index :encrypted_files, :encrypted_blob_key
    end
    
    # Update existing records to have max_views
    EncryptedPayload.where(max_views: nil).find_each do |payload|
      payload.update_column(:max_views, payload.remaining_views)
    end
    
    # Ensure file_data can be null (since we use Active Storage now)
    change_column_null :encrypted_files, :file_data, true if column_exists?(:encrypted_files, :file_data)
  end
end
