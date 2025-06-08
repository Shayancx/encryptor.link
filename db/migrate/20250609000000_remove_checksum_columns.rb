class RemoveChecksumColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :encrypted_payloads, :ciphertext_checksum, :string
    remove_column :encrypted_payloads, :nonce_checksum, :string
    remove_column :encrypted_files, :file_data_checksum, :string
  end
end
