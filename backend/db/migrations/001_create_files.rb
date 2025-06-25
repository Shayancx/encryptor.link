# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:encrypted_files) do
      primary_key :id
      String :file_id, null: false, unique: true, size: 36
      String :password_hash, null: false, size: 60
      String :salt, null: false, size: 64
      String :file_path, null: false, text: true
      String :original_filename, size: 255
      String :mime_type, size: 100
      Integer :file_size, null: false
      String :encryption_iv, null: false, size: 32
      DateTime :created_at, null: false
      DateTime :expires_at
      String :ip_address, size: 45

      index :file_id
      index :expires_at
    end

    create_table(:access_logs) do
      primary_key :id
      String :ip_address, null: false, size: 45
      String :endpoint, null: false, size: 100
      DateTime :accessed_at, null: false

      index %i[ip_address endpoint accessed_at]
    end
  end
end
