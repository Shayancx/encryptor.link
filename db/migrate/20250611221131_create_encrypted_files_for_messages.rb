class CreateEncryptedFilesForMessages < ActiveRecord::Migration[8.0]
  def change
    # Add message_id to encrypted_files if it doesn't exist
    unless column_exists?(:encrypted_files, :message_id)
      add_reference :encrypted_files, :message, type: :uuid, foreign_key: true, null: true
    end
  end
end
