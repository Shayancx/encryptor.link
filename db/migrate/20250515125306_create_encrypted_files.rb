class CreateEncryptedFiles < ActiveRecord::Migration[8.0]
  def change
    # Create the encrypted_files table for multi-file support
    create_table :encrypted_files, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.belongs_to :encrypted_payload, type: :uuid, null: false, foreign_key: true, index: true
      t.text :file_data, null: false
      t.string :file_name, null: false
      t.string :file_type
      t.integer :file_size, null: false
      t.timestamps
    end

    # Remove the file columns from encrypted_payloads as they'll now be in encrypted_files
    remove_column :encrypted_payloads, :file_data, :text, if_exists: true
    remove_column :encrypted_payloads, :file_name, :string, if_exists: true
    remove_column :encrypted_payloads, :file_type, :string, if_exists: true
    remove_column :encrypted_payloads, :file_size, :integer, if_exists: true
  end
end
