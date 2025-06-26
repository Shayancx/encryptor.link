# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'digest'

module DistributedStorage
  # Storage nodes configuration
  STORAGE_NODES = [
    { id: 'node1', path: File.expand_path('../storage/node1', __dir__), capacity: 10 * 1024 * 1024 * 1024 }, # 10GB
    { id: 'node2', path: File.expand_path('../storage/node2', __dir__), capacity: 10 * 1024 * 1024 * 1024 },
    { id: 'node3', path: File.expand_path('../storage/node3', __dir__), capacity: 10 * 1024 * 1024 * 1024 }
  ].freeze

  class << self
    def initialize_nodes
      STORAGE_NODES.each do |node|
        FileUtils.mkdir_p(node[:path])
        FileUtils.mkdir_p(File.join(node[:path], 'chunks'))
        FileUtils.mkdir_p(File.join(node[:path], 'temp'))
      end
      LOGGER.info "Initialized #{STORAGE_NODES.size} storage nodes"
    end

    def distribute_chunks(file_id, chunks)
      distribution_map = {}
      
      chunks.each_with_index do |chunk_data, index|
        # Select node based on load balancing
        node = select_optimal_node(chunk_data[:size])
        
        # Store chunk with replication
        primary_path = store_chunk(node, file_id, index, chunk_data[:data])
        replica_node = select_replica_node(node)
        replica_path = store_chunk(replica_node, file_id, index, chunk_data[:data])
        
        distribution_map[index] = {
          primary: { node: node[:id], path: primary_path },
          replica: { node: replica_node[:id], path: replica_path }
        }
        
        # Store metadata
        DB[:chunk_metadata].insert(
          file_id: file_id,
          chunk_index: index,
          node_id: node[:id],
          checksum: chunk_data[:checksum],
          size_bytes: chunk_data[:size],
          is_replica: false
        )
        
        DB[:chunk_metadata].insert(
          file_id: file_id,
          chunk_index: index,
          node_id: replica_node[:id],
          checksum: chunk_data[:checksum],
          size_bytes: chunk_data[:size],
          is_replica: true
        )
      end
      
      # Store distribution map in database
      DB[:distributed_files].insert(
        file_id: file_id,
        chunk_count: chunks.length,
        distribution_map: distribution_map.to_json,
        created_at: Time.now,
        expires_at: Time.now + (24 * 3600) # 24 hours default
      )
      
      LOGGER.info "Distributed #{chunks.length} chunks for file #{file_id}"
      distribution_map
    end

    def select_optimal_node(chunk_size)
      # Get node usage from database
      node_usage = {}
      STORAGE_NODES.each do |node|
        used_bytes = DB[:chunk_metadata]
                     .where(node_id: node[:id])
                     .sum(:size_bytes) || 0
        
        node_usage[node[:id]] = {
          node: node,
          used: used_bytes,
          available: node[:capacity] - used_bytes
        }
      end
      
      # Select node with most available space
      optimal = node_usage.values
                .select { |n| n[:available] >= chunk_size }
                .max_by { |n| n[:available] }
      
      raise 'No node has sufficient space' unless optimal
      
      optimal[:node]
    end

    def select_replica_node(primary_node)
      # Select a different node for replica
      available_nodes = STORAGE_NODES.reject { |n| n[:id] == primary_node[:id] }
      available_nodes.sample # For now, random selection
    end

    def store_chunk(node, file_id, chunk_index, chunk_data)
      chunk_dir = File.join(node[:path], 'chunks', file_id)
      FileUtils.mkdir_p(chunk_dir)
      
      chunk_path = File.join(chunk_dir, "chunk_#{chunk_index}.enc")
      File.open(chunk_path, 'wb') do |f|
        f.write(chunk_data)
      end
      
      chunk_path
    end

    def retrieve_chunk(file_id, chunk_index, node_id)
      node = STORAGE_NODES.find { |n| n[:id] == node_id }
      raise "Unknown node: #{node_id}" unless node
      
      chunk_path = File.join(node[:path], 'chunks', file_id, "chunk_#{chunk_index}.enc")
      raise "Chunk not found: #{chunk_index}" unless File.exist?(chunk_path)
      
      File.read(chunk_path, mode: 'rb')
    end

    def get_distribution_map(file_id)
      record = DB[:distributed_files].where(file_id: file_id).first
      raise "File not found: #{file_id}" unless record
      
      {
        file_id: file_id,
        chunk_count: record[:chunk_count],
        chunks: JSON.parse(record[:distribution_map])
      }
    end

    def cleanup_expired_files
      expired = DB[:distributed_files].where(Sequel.lit('expires_at < ?', Time.now))
      
      expired.each do |file|
        file_id = file[:file_id]
        distribution = JSON.parse(file[:distribution_map])
        
        # Delete all chunks
        distribution.each do |_index, locations|
          [locations['primary'], locations['replica']].each do |loc|
            node = STORAGE_NODES.find { |n| n[:id] == loc['node'] }
            next unless node
            
            chunk_dir = File.join(node[:path], 'chunks', file_id)
            FileUtils.rm_rf(chunk_dir) if Dir.exist?(chunk_dir)
          end
        end
        
        # Delete metadata
        DB[:chunk_metadata].where(file_id: file_id).delete
        DB[:distributed_files].where(file_id: file_id).delete
        
        LOGGER.info "Cleaned up expired file: #{file_id}"
      end
    end

    def node_health_check
      health_status = {}
      
      STORAGE_NODES.each do |node|
        begin
          # Check if node path is accessible
          accessible = Dir.exist?(node[:path])
          
          # Calculate usage
          used_bytes = DB[:chunk_metadata]
                       .where(node_id: node[:id])
                       .sum(:size_bytes) || 0
          
          # Update node status
          DB[:storage_nodes].insert_conflict(target: :node_id).update(
            node_id: node[:id],
            capacity_bytes: node[:capacity],
            used_bytes: used_bytes,
            status: accessible ? 'active' : 'offline',
            last_health_check: Time.now
          )
          
          health_status[node[:id]] = {
            accessible: accessible,
            used_bytes: used_bytes,
            capacity_bytes: node[:capacity],
            usage_percent: (used_bytes.to_f / node[:capacity] * 100).round(2)
          }
        rescue => e
          health_status[node[:id]] = {
            accessible: false,
            error: e.message
          }
        end
      end
      
      health_status
    end
  end
end
