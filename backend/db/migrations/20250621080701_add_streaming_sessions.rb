# frozen_string_literal: true

Sequel.migration do
  change do
    create_table?(:streaming_sessions) do
      primary_key :id
      String :session_id, null: false, unique: true
      String :file_id, null: false
      Integer :total_chunks, null: false
      Integer :received_chunks, default: 0
      String :status, default: 'uploading'
      DateTime :created_at, null: false
      DateTime :updated_at

      index :session_id
      index :created_at
    end

    # Ensure is_chunked column exists
    unless DB[:encrypted_files].columns.include?(:is_chunked)
      alter_table(:encrypted_files) do
        add_column :is_chunked, TrueClass, default: false
        add_index :is_chunked
      end
    end
  end
end
