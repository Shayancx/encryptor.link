# frozen_string_literal: true

module HealthMonitor
  CHECK_INTERVAL = 60 # seconds
  
  class << self
    def start_monitoring
      Thread.new do
        loop do
          begin
            check_all_nodes
            check_file_integrity
            ensure_replications
            rebalance_if_needed
          rescue => e
            LOGGER.error "Health monitor error: #{e.message}"
          end
          
          sleep CHECK_INTERVAL
        end
      end
    end
    
    def check_all_nodes
      results = DistributedStorage.node_health_check
      
      results.each do |node_id, status|
        if !status[:accessible]
          handle_node_failure(node_id)
        elsif status[:usage_percent] > 90
          LOGGER.warn "Node #{node_id} is at #{status[:usage_percent]}% capacity"
        end
      end
    end
    
    def handle_node_failure(failed_node_id)
      LOGGER.error "Node #{failed_node_id} is offline, initiating recovery"
      
      # Find all chunks on failed node
      affected_chunks = DB[:chunk_metadata]
                        .where(node_id: failed_node_id)
                        .all
      
      recovered = 0
      
      affected_chunks.each do |chunk|
        begin
          # Find alternative copy
          alternative = DB[:chunk_metadata]
                        .where(
                          file_id: chunk[:file_id],
                          chunk_index: chunk[:chunk_index]
                        )
                        .exclude(node_id: failed_node_id)
                        .first
          
          next unless alternative
          
          # Read from alternative
          chunk_data = DistributedStorage.retrieve_chunk(
            chunk[:file_id],
            chunk[:chunk_index],
            alternative[:node_id]
          )
          
          # Find new node for replica
          available_nodes = DistributedStorage::STORAGE_NODES
                            .reject { |n| 
                              n[:id] == failed_node_id || 
                              n[:id] == alternative[:node_id] 
                            }
          
          new_node = available_nodes.sample
          next unless new_node
          
          # Store on new node
          DistributedStorage.store_chunk(
            new_node,
            chunk[:file_id],
            chunk[:chunk_index],
            chunk_data
          )
          
          # Update metadata
          DB[:chunk_metadata]
            .where(id: chunk[:id])
            .update(node_id: new_node[:id])
          
          recovered += 1
        rescue => e
          LOGGER.error "Failed to recover chunk: #{e.message}"
        end
      end
      
      LOGGER.info "Recovered #{recovered}/#{affected_chunks.count} chunks from failed node #{failed_node_id}"
    end
    
    def check_file_integrity
      # Sample random files for integrity check
      sample_files = DB[:distributed_files]
                     .order(Sequel.lit('RANDOM()'))
                     .limit(10)
                     .all
      
      sample_files.each do |file|
        begin
          integrity = ChunkVerification.verify_file_integrity(file[:file_id])
          
          if integrity[:needs_repair]
            LOGGER.warn "File #{file[:file_id]} needs repair (health: #{integrity[:health_percentage]}%)"
            
            # Auto-repair if health is below threshold
            if integrity[:health_percentage] < 90
              ChunkVerification.repair_chunk(file[:file_id], 0) # Simplified
            end
          end
        rescue => e
          LOGGER.error "Integrity check failed for #{file[:file_id]}: #{e.message}"
        end
      end
    end
    
    def ensure_replications
      # Check recent files for proper replication
      recent_files = DB[:distributed_files]
                     .where(Sequel.lit('created_at > ?', Time.now - 3600))
                     .all
      
      recent_files.each do |file|
        ReplicaManager.ensure_replication(file[:file_id])
      end
    end
    
    def rebalance_if_needed
      # Check if rebalancing is needed
      node_stats = DistributedStorage.node_health_check
      usage_values = node_stats.values.map { |s| s[:usage_percent] || 0 }
      
      return if usage_values.empty?
      
      # Calculate standard deviation
      avg = usage_values.sum / usage_values.size
      variance = usage_values.map { |v| (v - avg) ** 2 }.sum / usage_values.size
      std_dev = Math.sqrt(variance)
      
      # Rebalance if standard deviation is high
      if std_dev > 15
        LOGGER.info "Storage imbalance detected (std dev: #{std_dev.round(2)}), rebalancing..."
        ReplicaManager.rebalance_storage
      end
    end
  end
end
