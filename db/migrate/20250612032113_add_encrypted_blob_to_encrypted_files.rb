class AddEncryptedBlobToEncryptedFiles < ActiveRecord::Migration[8.0]
  def change
    # Add a column to store the encrypted file's Active Storage blob key
    unless column_exists?(:encrypted_files, :encrypted_blob_key)
      add_column :encrypted_files, :encrypted_blob_key, :string
      add_index :encrypted_files, :encrypted_blob_key
    end

    # We'll keep file_data temporarily for migration
    # Remove the not-null constraint if it exists
    change_column_null :encrypted_files, :file_data, true if column_exists?(:encrypted_files, :file_data)
  end
end
