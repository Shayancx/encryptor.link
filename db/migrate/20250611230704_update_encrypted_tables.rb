class UpdateEncryptedTables < ActiveRecord::Migration[6.1]
  def change
    # Add missing columns to encrypted_payloads if they don't exist
    unless column_exists?(:encrypted_payloads, :encrypted_data)
      add_column :encrypted_payloads, :encrypted_data, :text
    end
    
    unless column_exists?(:encrypted_payloads, :expires_at)
      add_column :encrypted_payloads, :expires_at, :datetime
    end
    
    unless column_exists?(:encrypted_payloads, :max_views)
      add_column :encrypted_payloads, :max_views, :integer
    end
    
    unless column_exists?(:encrypted_payloads, :burn_after_reading)
      add_column :encrypted_payloads, :burn_after_reading, :boolean, default: false
    end
    
    unless column_exists?(:encrypted_payloads, :password_digest)
      add_column :encrypted_payloads, :password_digest, :string
    end
    
    # Add missing columns to encrypted_files if they don't exist
    unless column_exists?(:encrypted_files, :name)
      add_column :encrypted_files, :name, :string
    end
    
    unless column_exists?(:encrypted_files, :file_metadata)
      add_column :encrypted_files, :file_metadata, :text
    end
    
    # Remove columns that don't match the model if they exist
    if column_exists?(:encrypted_payloads, :payload) && 
       !ActiveRecord::Base.connection.columns(:encrypted_payloads).map(&:name).include?('encrypted_data')
      remove_column :encrypted_payloads, :payload
    end
    
    if column_exists?(:encrypted_files, :file_id) &&
       !ActiveRecord::Base.connection.columns(:encrypted_files).map(&:name).include?('id')
      rename_column :encrypted_files, :file_id, :file_identifier
    end
  end
end
