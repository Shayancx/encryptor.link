class EnsureEncryptedPayloadsSchema < ActiveRecord::Migration[6.1]
  def change
    # Make sure encrypted_payloads table exists
    unless table_exists?(:encrypted_payloads)
      create_table :encrypted_payloads, id: :uuid do |t|
        t.text :payload, null: false
        t.timestamps
      end
    end
    
    # Make sure encrypted_files table exists with proper references
    unless table_exists?(:encrypted_files)
      create_table :encrypted_files, id: :uuid do |t|
        t.string :file_id, null: false
        t.references :encrypted_payload, null: false, foreign_key: true, type: :uuid
        t.binary :encrypted_file
        t.string :content_type
        t.integer :size
        t.timestamps
      end
    else
      # If table exists, ensure the reference to encrypted_payload is correct
      unless column_exists?(:encrypted_files, :encrypted_payload_id)
        add_reference :encrypted_files, :encrypted_payload, null: false, foreign_key: true, type: :uuid
      end
      
      # Ensure file_id column exists and is not null
      unless column_exists?(:encrypted_files, :file_id)
        add_column :encrypted_files, :file_id, :string, null: false
      end
    end
    
    # Create indexes for better performance
    add_index :encrypted_files, :file_id, unique: true unless index_exists?(:encrypted_files, :file_id)
  end
end
