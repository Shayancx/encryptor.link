class AddChecksumsToPayloads < ActiveRecord::Migration[8.0]
  def change
    add_column :encrypted_payloads, :ciphertext_checksum, :string
    add_column :encrypted_payloads, :nonce_checksum, :string
    add_column :encrypted_files, :file_data_checksum, :string

    add_index :encrypted_payloads, :ciphertext_checksum
    add_index :encrypted_files, :file_data_checksum
  end
end
