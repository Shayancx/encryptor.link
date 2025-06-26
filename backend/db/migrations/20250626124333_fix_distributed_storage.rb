# frozen_string_literal: true

Sequel.migration do
  change do
    # Only create tables if they don't exist
    create_table?(:distributed_files) do
      primary_key :id
      String :file_id, null: false, unique: true
      Integer :chunk_count, null: false
      Text :distribution_map, null: false
      String :encryption_metadata
      DateTime :created_at
      DateTime :expires_at
      
      index :file_id
      index :expires_at
    end
    
    create_table?(:storage_nodes) do
      primary_key :id
      String :node_id, null: false, unique: true
      String :node_url
      Integer :capacity_bytes, null: false, default: 10737418240
      Integer :used_bytes, default: 0
      String :status, default: 'active'
      DateTime :last_health_check
      
      index :node_id
    end
    
    create_table?(:chunk_metadata) do
      primary_key :id
      String :file_id, null: false
      Integer :chunk_index, null: false
      String :node_id, null: false
      String :checksum, null: false
      Integer :size_bytes
      Boolean :is_replica, default: false
      String :iv
      Text :metadata
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
      
      index [:file_id, :chunk_index]
      index :node_id
      index [:file_id, :node_id]
    end
    
    create_table?(:distributed_sessions) do
      primary_key :id
      String :session_id, null: false, unique: true
      String :file_id, null: false
      Integer :total_chunks, null: false
      Integer :total_size
      Text :metadata
      DateTime :created_at
      Integer :account_id
      
      index :session_id
      index :file_id
    end
    
    create_table?(:distributed_chunks) do
      primary_key :id
      String :file_id, null: false
      Integer :chunk_index, null: false
      String :primary_node, null: false
      String :replica_node, null: false
      String :checksum
      Text :metadata
      Integer :size_bytes
      DateTime :uploaded_at
      
      index [:file_id, :chunk_index]
    end
    
    # Initialize storage nodes if they don't exist
    if from(:storage_nodes).count == 0
      from(:storage_nodes).multi_insert([
        { node_id: 'node1', capacity_bytes: 10737418240, status: 'active' },
        { node_id: 'node2', capacity_bytes: 10737418240, status: 'active' },
        { node_id: 'node3', capacity_bytes: 10737418240, status: 'active' }
      ])
    end
  end
end
