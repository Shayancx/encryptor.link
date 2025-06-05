class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for cleanup queries
    unless index_exists?(:encrypted_payloads, [ :expires_at, :remaining_views ], name: 'idx_payloads_cleanup')
      add_index :encrypted_payloads, [ :expires_at, :remaining_views ],
                name: 'idx_payloads_cleanup'
    end

    # Add index for encrypted files lookup
    unless index_exists?(:encrypted_files, :encrypted_payload_id, name: 'idx_encrypted_files_payload')
      add_index :encrypted_files, :encrypted_payload_id,
                name: 'idx_encrypted_files_payload'
    end

    # Add index for created_at for time-based queries
    unless index_exists?(:encrypted_payloads, :created_at, name: 'idx_payloads_created_at')
      add_index :encrypted_payloads, :created_at,
                name: 'idx_payloads_created_at'
    end
  end
end
