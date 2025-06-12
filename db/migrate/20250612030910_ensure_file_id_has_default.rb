class EnsureFileIdHasDefault < ActiveRecord::Migration[8.0]
  def change
    # Ensure file_id column exists
    unless column_exists?(:encrypted_files, :file_id)
      add_column :encrypted_files, :file_id, :string
    end
    
    # Set default value for existing records
    EncryptedFile.where(file_id: nil).find_each do |file|
      file.update_column(:file_id, SecureRandom.uuid)
    end
    
    # Make it not null with a default
    change_column :encrypted_files, :file_id, :string, null: false, default: -> { 'gen_random_uuid()' }
  end
end
