# frozen_string_literal: true

require 'digest'

module ChunkVerification
  class << self
    def calculate_checksum(data)
      Digest::SHA256.hexdigest(data)
    end
    
    def verify_chunk(chunk_data, expected_checksum)
      actual_checksum = calculate_checksum(chunk_data)
      actual_checksum == expected_checksum
    end
    
    def verify_chunk_integrity(file_id, chunk_index)
      # Get chunk metadata
      metadata = DB[:chunk_metadata]
                 .where(file_id: file_id, chunk_index: chunk_index)
                 .all
      
      results = {}
      
      metadata.each do |chunk_info|
        begin
          # Read chunk from storage
          chunk_data = DistributedStorage.retrieve_chunk(
            file_id,
            chunk_index,
            chunk_info[:node_id]
          )
          
          # Verify checksum
          is_valid = verify_chunk(chunk_data, chunk_info[:checksum])
          
          results[chunk_info[:node_id]] = {
            valid: is_valid,
            is_replica: chunk_info[:is_replica],
            size: chunk_info[:size_bytes]
          }
        rescue => e
          results[chunk_info[:node_id]] = {
            valid: false,
            error: e.message,
            is_replica: chunk_info[:is_replica]
          }
        end
      end
      
      results
    end
    
    def repair_chunk(file_id, chunk_index)
      # Find a valid copy
      integrity_results = verify_chunk_integrity(file_id, chunk_index)
      
      valid_node = integrity_results.find { |_node_id, result| result[:valid] }
      return false unless valid_node
      
      valid_node_id = valid_node[0]
      
      # Read valid chunk
      valid_chunk_data = DistributedStorage.retrieve_chunk(
        file_id,
        chunk_index,
        valid_node_id
      )
      
      # Repair invalid copies
      repaired = []
      
      integrity_results.each do |node_id, result|
        next if result[:valid] || node_id == valid_node_id
        
        begin
          # Find the node
          node = DistributedStorage::STORAGE_NODES.find { |n| n[:id] == node_id }
          next unless node
          
          # Rewrite chunk
          DistributedStorage.store_chunk(node, file_id, chunk_index, valid_chunk_data)
          repaired << node_id
          
          LOGGER.info "Repaired chunk #{chunk_index} on node #{node_id}"
        rescue => e
          LOGGER.error "Failed to repair chunk #{chunk_index} on node #{node_id}: #{e.message}"
        end
      end
      
      repaired
    end
    
    def verify_file_integrity(file_id)
      distribution = DistributedStorage.get_distribution_map(file_id)
      results = {
        file_id: file_id,
        total_chunks: distribution[:chunk_count],
        chunk_status: {}
      }
      
      distribution[:chunk_count].times do |i|
        results[:chunk_status][i] = verify_chunk_integrity(file_id, i)
      end
      
      # Calculate overall health
      total_copies = results[:chunk_status].values.flat_map(&:values).count
      valid_copies = results[:chunk_status].values.flat_map(&:values).count { |r| r[:valid] }
      
      results[:health_percentage] = (valid_copies.to_f / total_copies * 100).round(2)
      results[:needs_repair] = results[:health_percentage] < 100
      
      results
    end
  end
end
