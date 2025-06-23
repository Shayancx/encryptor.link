# Read current app.rb
app_content = File.read('app.rb')

# Find and update the streaming chunk endpoint
new_chunk_endpoint = <<-'RUBY_CODE'
        # Upload chunk - handle multipart form data
        r.post 'chunk' do
          begin
            # Log request details
            LOGGER.info "Chunk upload request - Content-Type: #{request.content_type}"
            
            # Parse parameters
            session_id = request.params['session_id']
            chunk_index = request.params['chunk_index']
            iv = request.params['iv']
            
            # Validate parameters
            unless session_id && chunk_index && iv
              response.status = 400
              next { error: "Missing required fields: session_id, chunk_index, or iv" }
            end
            
            chunk_index = chunk_index.to_i
            
            # Handle chunk data from multipart upload
            chunk_data = nil
            chunk_file = request.params['chunk_data']
            
            if chunk_file.nil?
              response.status = 400
              next { error: 'Missing chunk_data file' }
            end
            
            # Handle different file upload formats
            if chunk_file.is_a?(String)
              # Base64 encoded data
              chunk_data = chunk_file
            elsif chunk_file.respond_to?(:read)
              # Rack::Multipart::UploadedFile
              chunk_data = chunk_file.read
              chunk_file.rewind if chunk_file.respond_to?(:rewind)
            elsif chunk_file.is_a?(Hash)
              # Standard Rack file upload hash
              if chunk_file[:tempfile]
                chunk_data = chunk_file[:tempfile].read
              elsif chunk_file['tempfile']
                chunk_data = chunk_file['tempfile'].read
              end
            else
              LOGGER.error "Unknown chunk_data format: #{chunk_file.class}"
              response.status = 400
              next { error: "Invalid chunk data format" }
            end
            
            unless chunk_data
              response.status = 400
              next { error: 'Could not read chunk data' }
            end
            
            # Log chunk details
            LOGGER.info "Storing chunk #{chunk_index} for session #{session_id} (size: #{chunk_data.bytesize} bytes)"
            
            # Store chunk
            result = StreamingUpload.store_chunk(session_id, chunk_index, chunk_data, iv)
            
            LOGGER.info "Chunk #{chunk_index} stored successfully: #{result[:chunks_received]}/#{result[:total_chunks]}"
            
            result
          rescue => e
            LOGGER.error "Chunk upload error: #{e.message}"
            LOGGER.error e.backtrace.join("\n")
            response.status = 500
            { error: "Failed to upload chunk: #{e.message}" }
          end
        end
RUBY_CODE

# Replace the chunk endpoint
if app_content.include?('# Upload chunk')
  app_content.gsub!(/# Upload chunk.*?(?=# Finalize upload)/m, new_chunk_endpoint + "\n        ")
else
  puts "Warning: Could not find chunk endpoint marker"
end

# Write updated content
File.write('app.rb', app_content)
puts "✓ Updated chunk endpoint in app.rb"
