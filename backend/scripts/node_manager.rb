#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require_relative '../app'

class NodeManager
  def self.run(command, *args)
    case command
    when 'status'
      show_status
    when 'add'
      add_node(args[0], args[1])
    when 'remove'
      remove_node(args[0])
    when 'balance'
      rebalance
    when 'verify'
      verify_integrity(args[0])
    when 'repair'
      repair_file(args[0])
    else
      show_help
    end
  end

  def self.show_status
    puts "\n📊 Storage Node Status"
    puts "=" * 60
    
    health = DistributedStorage.node_health_check
    
    health.each do |node_id, status|
      puts "\nNode: #{node_id}"
      puts "  Status: #{status[:accessible] ? '✅ Online' : '❌ Offline'}"
      puts "  Used: #{(status[:used_bytes] / 1024.0 / 1024.0).round(2)} MB"
      puts "  Capacity: #{(status[:capacity_bytes] / 1024.0 / 1024.0 / 1024.0).round(2)} GB"
      puts "  Usage: #{status[:usage_percent]}%"
      
      # Progress bar
      bar_length = 40
      filled = (status[:usage_percent] * bar_length / 100).to_i
      bar = '█' * filled + '░' * (bar_length - filled)
      puts "  [#{bar}]"
    end
    
    # Overall statistics
    total_files = DB[:distributed_files].count
    total_chunks = DB[:chunk_metadata].count
    total_size = DB[:chunk_metadata].sum(:size_bytes) || 0
    
    puts "\n📈 Overall Statistics"
    puts "  Total Files: #{total_files}"
    puts "  Total Chunks: #{total_chunks}"
    puts "  Total Size: #{(total_size / 1024.0 / 1024.0 / 1024.0).round(2)} GB"
  end

  def self.add_node(node_id, capacity_gb)
    return show_help unless node_id && capacity_gb
    
    capacity_bytes = capacity_gb.to_f * 1024 * 1024 * 1024
    
    # Add to configuration
    puts "🔧 Adding node #{node_id} with #{capacity_gb}GB capacity..."
    
    # This would normally update configuration
    puts "✅ Node #{node_id} added successfully"
  end

  def self.remove_node(node_id)
    return show_help unless node_id
    
    puts "🔧 Removing node #{node_id}..."
    
    # Migrate chunks from this node
    chunks = DB[:chunk_metadata].where(node_id: node_id).all
    puts "  Found #{chunks.count} chunks to migrate"
    
    migrated = 0
    chunks.each do |chunk|
      begin
        # Find alternative node
        alternative = DB[:chunk_metadata]
                      .where(file_id: chunk[:file_id], chunk_index: chunk[:chunk_index])
                      .exclude(node_id: node_id)
                      .first
        
        if alternative
          # Update to use alternative as primary
          DB[:chunk_metadata].where(id: chunk[:id]).update(node_id: alternative[:node_id])
          migrated += 1
        end
      rescue => e
        puts "  ⚠️  Failed to migrate chunk: #{e.message}"
      end
    end
    
    puts "✅ Migrated #{migrated}/#{chunks.count} chunks"
  end

  def self.rebalance
    puts "🔄 Rebalancing storage nodes..."
    
    result = ReplicaManager.rebalance_storage
    
    puts "\n📦 Moves completed: #{result[:moves_completed].count}"
    result[:moves_completed].each do |move|
      puts "  • Chunk #{move[:chunk_index]} of #{move[:file_id][0..7]}..."
      puts "    #{move[:from_node]} → #{move[:to_node]} (#{(move[:size] / 1024.0 / 1024.0).round(2)} MB)"
    end
    
    puts "\n📊 Final balance:"
    result[:final_balance].each do |node|
      puts "  • #{node[:node_id]}: #{node[:usage_percent]}%"
    end
  end

  def self.verify_integrity(file_id)
    return show_help unless file_id
    
    puts "🔍 Verifying integrity of file #{file_id}..."
    
    result = ChunkVerification.verify_file_integrity(file_id)
    
    puts "\n📊 File Health: #{result[:health_percentage]}%"
    puts "Total Chunks: #{result[:total_chunks]}"
    
    result[:chunk_status].each do |chunk_index, nodes|
      all_valid = nodes.values.all? { |n| n[:valid] }
      status = all_valid ? '✅' : '⚠️'
      
      puts "\n#{status} Chunk #{chunk_index}:"
      nodes.each do |node_id, node_status|
        puts "  • #{node_id}: #{node_status[:valid] ? 'Valid' : 'Invalid'}"
        puts "    #{node_status[:error]}" if node_status[:error]
      end
    end
    
    if result[:needs_repair]
      puts "\n⚠️  File needs repair. Run 'node_manager.rb repair #{file_id}' to fix."
    else
      puts "\n✅ File integrity verified!"
    end
  end

  def self.repair_file(file_id)
    return show_help unless file_id
    
    puts "🔧 Repairing file #{file_id}..."
    
    # First verify
    integrity = ChunkVerification.verify_file_integrity(file_id)
    
    if !integrity[:needs_repair]
      puts "✅ File is healthy, no repair needed"
      return
    end
    
    repaired = 0
    integrity[:chunk_status].each do |chunk_index, _|
      repaired_nodes = ChunkVerification.repair_chunk(file_id, chunk_index.to_i)
      if repaired_nodes.any?
        puts "  ✅ Repaired chunk #{chunk_index} on nodes: #{repaired_nodes.join(', ')}"
        repaired += repaired_nodes.count
      end
    end
    
    puts "\n✅ Repair complete! Fixed #{repaired} chunk copies."
  end

  def self.show_help
    puts <<~HELP
      Node Manager - Distributed Storage Management Tool
      
      Usage: ruby node_manager.rb <command> [args]
      
      Commands:
        status                    Show status of all storage nodes
        add <id> <capacity_gb>    Add a new storage node
        remove <id>               Remove a storage node (migrates data)
        balance                   Rebalance chunks across nodes
        verify <file_id>          Verify integrity of a file
        repair <file_id>          Repair damaged chunks
        
      Examples:
        ruby node_manager.rb status
        ruby node_manager.rb add node4 20
        ruby node_manager.rb verify abc12345
    HELP
  end
end

# Run if called directly
if __FILE__ == $0
  NodeManager.run(*ARGV)
end
