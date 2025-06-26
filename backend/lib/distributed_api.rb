# frozen_string_literal: true

require_relative 'distributed_storage'
require_relative 'chunk_verification'
require_relative 'replica_manager'

module DistributedAPI
  def self.included(app)
    app.class_eval do
      r.on 'api' do
        r.on 'distributed' do
          # Initialize distributed upload
          r.post 'initialize' do
            data = request.params
            
            unless data['sessionId'] && data['fileId'] && data['totalChunks'] && data['password']
              response.status = 400
              next { error: 'Missing required fields' }
            end
            
            # Validate password
            password_check = Crypto.validate_password_strength(data['password'])
            unless password_check[:valid]
              response.status = 400
              next { error: password_check[:error] }
            end
            
            # Store session info
            DB[:distributed_sessions].insert(
              session_id: data['sessionId'],
              file_id: data['fileId'],
              total_chunks: data['totalChunks'],
              total_size: data['totalSize'],
              metadata: data['metadata'].to_json,
              created_at: Time.now,
              account_id: authenticated? ? current_user[:id] : nil
            )
            
            {
              success: true,
              sessionId: data['sessionId'],
              fileId: data['fileId']
            }
          end
          
          # Upload chunk to distributed storage
          r.post 'chunk' do
            file_id = request.params['file_id']
            chunk_index = request.params['chunk_index'].to_i
            checksum = request.params['checksum']
            metadata = request.params['metadata']
            chunk_file = request.params['chunk_data']
            
            unless file_id && chunk_file
              response.status = 400
              next { error: 'Missing required fields' }
            end
            
            # Read chunk data
            chunk_data = if chunk_file.is_a?(Hash) && chunk_file[:tempfile]
                           chunk_file[:tempfile].read
                         else
                           chunk_file
                         end
            
            # Select storage node
            node = DistributedStorage.select_optimal_node(chunk_data.bytesize)
            
            # Store with replication
            primary_path = DistributedStorage.store_chunk(node, file_id, chunk_index, chunk_data)
            replica_node = DistributedStorage.select_replica_node(node)
            replica_path = DistributedStorage.store_chunk(replica_node, file_id, chunk_index, chunk_data)
            
            # Update session
            DB[:distributed_chunks].insert(
              file_id: file_id,
              chunk_index: chunk_index,
              primary_node: node[:id],
              replica_node: replica_node[:id],
              checksum: checksum,
              metadata: metadata,
              size_bytes: chunk_data.bytesize,
              uploaded_at: Time.now
            )
            
            {
              success: true,
              chunkIndex: chunk_index,
              nodeId: node[:id],
              replicaNodeId: replica_node[:id]
            }
          end
          
          # Finalize distributed upload
          r.post 'finalize' do
            data = JSON.parse(request.body.read)
            file_id = data['file_id']
            salt = data['salt']
            
            unless file_id && salt
              response.status = 400
              next { error: 'Missing required fields' }
            end
            
            # Get all chunks
            chunks = DB[:distributed_chunks]
                     .where(file_id: file_id)
                     .order(:chunk_index)
                     .all
            
            # Build distribution map
            distribution_map = {}
            chunks.each do |chunk|
              distribution_map[chunk[:chunk_index]] = {
                primary: {
                  node: chunk[:primary_node],
                  path: File.join('chunks', file_id, "chunk_#{chunk[:chunk_index]}.enc")
                },
                replica: {
                  node: chunk[:replica_node],
                  path: File.join('chunks', file_id, "chunk_#{chunk[:chunk_index]}.enc")
                }
              }
            end
            
            # Store in distributed files table
            DB[:distributed_files].insert(
              file_id: file_id,
              chunk_count: chunks.length,
              distribution_map: distribution_map.to_json,
              encryption_metadata: { salt: salt }.to_json,
              created_at: Time.now,
              expires_at: Time.now + (24 * 3600)
            )
            
            # Clean up temporary data
            DB[:distributed_chunks].where(file_id: file_id).delete
            
            {
              success: true,
              fileId: file_id
            }
          end
          
          # Get distribution map
          r.get 'map', String do |file_id|
            begin
              map = DistributedStorage.get_distribution_map(file_id)
              map
            rescue => e
              response.status = 404
              { error: e.message }
            end
          end
          
          # Retrieve chunk from distributed storage
          r.post 'retrieve' do
            data = JSON.parse(request.body.read)
            
            file_id = data['file_id']
            chunk_index = data['chunk_index']
            node_id = data['node_id']
            password = data['password']
            
            # Verify password (simplified for now)
            # In production, verify against stored hash
            
            begin
              chunk_data = DistributedStorage.retrieve_chunk(file_id, chunk_index, node_id)
              
              # Get metadata
              metadata = DB[:chunk_metadata]
                         .where(file_id: file_id, chunk_index: chunk_index, node_id: node_id)
                         .first
              
              {
                encryptedData: Base64.strict_encode64(chunk_data),
                iv: metadata[:iv] || '',
                checksum: metadata[:checksum],
                metadata: metadata[:metadata] || '',
                salt: JSON.parse(DB[:distributed_files].where(file_id: file_id).first[:encryption_metadata])['salt']
              }
            rescue => e
              response.status = 500
              { error: e.message }
            end
          end
          
          # Node health status
          r.get 'health' do
            {
              nodes: DistributedStorage.node_health_check,
              timestamp: Time.now.iso8601
            }
          end
          
          # Verify file integrity
          r.get 'verify', String do |file_id|
            begin
              results = ChunkVerification.verify_file_integrity(file_id)
              results
            rescue => e
              response.status = 404
              { error: e.message }
            end
          end
          
          # Repair damaged chunks
          r.post 'repair', String do |file_id|
            begin
              integrity = ChunkVerification.verify_file_integrity(file_id)
              repaired_chunks = []
              
              integrity[:chunk_status].each do |chunk_index, _status|
                repaired_nodes = ChunkVerification.repair_chunk(file_id, chunk_index.to_i)
                repaired_chunks << {
                  chunk_index: chunk_index,
                  repaired_nodes: repaired_nodes
                } if repaired_nodes.any?
              end
              
              {
                file_id: file_id,
                repaired_chunks: repaired_chunks,
                success: true
              }
            rescue => e
              response.status = 500
              { error: e.message }
            end
          end
        end
      end
    end
  end
end
