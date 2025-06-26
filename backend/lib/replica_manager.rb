# frozen_string_literal: true

module ReplicaManager
  REPLICATION_FACTOR = 2 # Primary + 1 replica
  
  class << self
    def ensure_replication(file_id)
      distribution = DistributedStorage.get_distribution_map(file_id)
      replication_status = []
      
      distribution[:chunk_count].times do |chunk_index|
        # Get current replicas
        replicas = DB[:chunk_metadata]
                   .where(file_id: file_id, chunk_index: chunk_index)
                   .all
        
        if replicas.count < REPLICATION_FACTOR
          # Need more replicas
          primary = replicas.find { |r| !r[:is_replica] }
          next unless primary
          
          # Read chunk from primary
          chunk_data = DistributedStorage.retrieve_chunk(
            file_id,
            chunk_index,
            primary[:node_id]
          )
          
          # Find nodes without this chunk
          existing_nodes = replicas.map { |r| r[:node_id] }
          available_nodes = DistributedStorage::STORAGE_NODES
                            .reject { |n| existing_nodes.include?(n[:id]) }
          
          # Create missing replicas
          replicas_needed = REPLICATION_FACTOR - replicas.count
          available_nodes.sample(replicas_needed).each do |node|
            DistributedStorage.store_chunk(node, file_id, chunk_index, chunk_data)
            
            DB[:chunk_metadata].insert(
              file_id: file_id,
              chunk_index: chunk_index,
              node_id: node[:id],
              checksum: primary[:checksum],
              size_bytes: primary[:size_bytes],
              is_replica: true
            )
            
            replication_status << {
              chunk_index: chunk_index,
              new_replica_node: node[:id]
            }
          end
        end
      end
      
      replication_status
    end
    
    def rebalance_storage
      # Get usage statistics
      node_usage = {}
      
      DistributedStorage::STORAGE_NODES.each do |node|
        used = DB[:chunk_metadata]
               .where(node_id: node[:id])
               .sum(:size_bytes) || 0
        
        node_usage[node[:id]] = {
          node: node,
          used_bytes: used,
          usage_percent: (used.to_f / node[:capacity] * 100).round(2)
        }
      end
      
      # Find imbalanced nodes
      avg_usage = node_usage.values.map { |n| n[:usage_percent] }.sum / node_usage.size
      threshold = 10 # 10% deviation threshold
      
      overloaded = node_usage.select { |_id, info| info[:usage_percent] > avg_usage + threshold }
      underloaded = node_usage.select { |_id, info| info[:usage_percent] < avg_usage - threshold }
      
      moves = []
      
      overloaded.each do |source_id, source_info|
        # Find chunks to move
        chunks_to_move = DB[:chunk_metadata]
                         .where(node_id: source_id, is_replica: true)
                         .order(Sequel.desc(:size_bytes))
                         .limit(5)
                         .all
        
        chunks_to_move.each do |chunk|
          # Find target node
          target = underloaded.min_by { |_id, info| info[:usage_percent] }
          next unless target
          
          target_id = target[0]
          target_node = target[1][:node]
          
          begin
            # Move chunk
            chunk_data = DistributedStorage.retrieve_chunk(
              chunk[:file_id],
              chunk[:chunk_index],
              source_id
            )
            
            DistributedStorage.store_chunk(
              target_node,
              chunk[:file_id],
              chunk[:chunk_index],
              chunk_data
            )
            
            # Update metadata
            DB[:chunk_metadata]
              .where(
                file_id: chunk[:file_id],
                chunk_index: chunk[:chunk_index],
                node_id: source_id
              )
              .update(node_id: target_id)
            
            # Delete from source
            source_node = source_info[:node]
            chunk_path = File.join(
              source_node[:path],
              'chunks',
              chunk[:file_id],
              "chunk_#{chunk[:chunk_index]}.enc"
            )
            File.delete(chunk_path) if File.exist?(chunk_path)
            
            # Update usage stats
            source_info[:used_bytes] -= chunk[:size_bytes]
            target[1][:used_bytes] += chunk[:size_bytes]
            
            moves << {
              file_id: chunk[:file_id],
              chunk_index: chunk[:chunk_index],
              from_node: source_id,
              to_node: target_id,
              size: chunk[:size_bytes]
            }
          rescue => e
            LOGGER.error "Failed to move chunk: #{e.message}"
          end
        end
      end
      
      {
        moves_completed: moves,
        final_balance: node_usage.map { |id, info| 
          { 
            node_id: id, 
            usage_percent: info[:usage_percent] 
          } 
        }
      }
    end
  end
end
