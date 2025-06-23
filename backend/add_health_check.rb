app_content = File.read('app.rb')

health_check = <<-'RUBY_CODE'
        # Health check for streaming
        r.get 'health' do
          begin
            # Check temp storage
            temp_exists = Dir.exist?(StreamingUpload::TEMP_STORAGE_PATH)
            
            # Check database
            db_healthy = DB.test_connection
            
            # Get session count
            session_count = Dir.glob(File.join(StreamingUpload::TEMP_STORAGE_PATH, '*')).count
            
            {
              status: 'healthy',
              streaming: {
                temp_storage: temp_exists,
                active_sessions: session_count,
                database: db_healthy
              }
            }
          rescue => e
            response.status = 503
            {
              status: 'unhealthy',
              error: e.message
            }
          end
        end
RUBY_CODE

# Add before finalize endpoint
if app_content.include?('# Finalize upload')
  app_content.sub!('# Finalize upload', health_check + "\n        # Finalize upload")
  File.write('app.rb', app_content)
  puts "✓ Added health check endpoint"
end
