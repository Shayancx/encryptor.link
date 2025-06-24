require 'bundler/setup'
Bundler.require

require 'roda'
require 'sequel'
require 'json'
require 'logger'
require 'base64'
require 'bcrypt'
require 'securerandom'

# Load configuration first
require_relative 'config/environment'

# Load application modules
require_relative 'lib/crypto'
require_relative 'lib/file_storage'
require_relative 'lib/rate_limiter'
require_relative 'lib/streaming_upload'


require_relative 'lib/services/email_service'

# Initialize storage
FileStorage.initialize_storage

# Database setup
DB = Sequel.connect(Environment.database_url)
DB.loggers << Logger.new('logs/db.log') if Environment.development?

# Ensure database schema is up to date
begin
  Sequel.extension :migration
  migration_dir = File.expand_path('db/migrations', __dir__)
  Sequel::Migrator.run(DB, migration_dir)
rescue => e
  warn "Database migration failed: #{e.message}"
  raise
end

# Logger setup
LOGGER = Logger.new('logs/app.log', 'daily')

# Load JWT secret from environment
JWT_SECRET = Environment.jwt_secret

# Simple JWT implementation
module SimpleJWT
  def self.encode(payload)
    require 'jwt'
    JWT.encode(payload, JWT_SECRET, 'HS256')
  end
  
  def self.decode(token)
    require 'jwt'
    JWT.decode(token, JWT_SECRET, true, algorithm: 'HS256')[0]
  rescue JWT::DecodeError
    nil
  end
end

class EncryptorAPI < Roda
  plugin :json
  plugin :json_parser
  plugin :all_verbs
  plugin :heartbeat, path: '/api/status'
  plugin :request_headers
  plugin :halt
  
  # CORS headers
  plugin :default_headers,
    'Access-Control-Allow-Origin' => Environment.frontend_url,
    'Access-Control-Allow-Methods' => 'GET, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers' => 'Content-Type, Authorization',
    'Access-Control-Max-Age' => '86400'
  
  # Helper methods
  def current_user
    return @current_user if defined?(@current_user)
    
    auth_header = request.env['HTTP_AUTHORIZATION']
    return @current_user = nil unless auth_header && auth_header.start_with?('Bearer ')
    
    token = auth_header.sub('Bearer ', '')
    payload = SimpleJWT.decode(token)
    return @current_user = nil unless payload
    
    @current_user = DB[:accounts].where(id: payload['account_id']).first
  end
  
  def authenticated?
    !current_user.nil?
  end
  
  def upload_limit
    FileStorage.upload_limit_for_user(authenticated?)
  end
  
  route do |r|
    # Handle preflight
    r.options do
      response.status = 204
      nil
    end
    
    # Get client IP
    client_ip = request.env['HTTP_X_FORWARDED_FOR']&.split(',')&.first || request.ip
    
    r.on 'api' do
      # Auth endpoints
      r.on 'auth' do
        # Register
        r.post 'register' do
          email = request.params['login']
          password = request.params['password']
          
          unless email && password
            response.status = 400
            next { error: 'Email and password required' }
          end
          
          # Check if exists
          if DB[:accounts].where(email: email).count > 0
            response.status = 400
            next { error: 'Email already registered' }
          end
          
          # Validate password
          unless password.length >= 8 && password =~ /[A-Z]/ && password =~ /[a-z]/ && password =~ /\d/
            response.status = 400
            next { error: 'Password must be at least 8 characters with uppercase, lowercase, and number' }
          end
          
          # Create account
          account_id = DB[:accounts].insert(
            email: email,
            status_id: 'verified',
            password_hash: BCrypt::Password.create(password),
            created_at: Time.now
          )
          
          # Send welcome email
          if Environment.email_enabled?
            Thread.new do
              EmailService.send_welcome_email(email)
            end
          end
          
          # Generate token
          token = SimpleJWT.encode({ account_id: account_id, email: email })
          
          {
            success: true,
            access_token: token,
            account: {
              id: account_id,
              email: email
            }
          }
        end
        
        # Login
        r.post 'login' do
          email = request.params['login']
          password = request.params['password']
          
          unless email && password
            response.status = 400
            next { error: 'Email and password required' }
          end
          
          # Find account
          account = DB[:accounts].where(email: email).first
          
          unless account && BCrypt::Password.new(account[:password_hash]) == password
            response.status = 401
            next { error: 'Invalid email or password' }
          end
          
          # Update last login
          DB[:accounts].where(id: account[:id]).update(last_login_at: Time.now)
          
          # Generate token
          token = SimpleJWT.encode({ account_id: account[:id], email: account[:email] })
          
          {
            success: true,
            access_token: token,
            account: {
              id: account[:id],
              email: account[:email]
            }
          }
        end
        
        # Logout (just a placeholder since we're using JWT)
        r.post 'logout' do
          { success: true }
        end
        
        # Status
        r.get 'status' do
          if authenticated?
            {
              authenticated: true,
              account: {
                id: current_user[:id],
                email: current_user[:email],
                upload_limit: upload_limit,
                upload_limit_mb: upload_limit / 1024 / 1024
              }
            }
          else
            {
              authenticated: false,
              upload_limit: upload_limit,
              upload_limit_mb: upload_limit / 1024 / 1024
            }
          end
        end
        
        # Password reset request
        r.post 'reset-password-request' do
          email = request.params['login']
          
          unless email
            response.status = 400
            next { error: 'Email address required' }
          end
          
          # Find account
          account = DB[:accounts].where(email: email).first
          
          if account
            # Generate reset token
            reset_token = SecureRandom.hex(32)
            expires_at = Time.now + 3600  # 1 hour
            
            # Store reset token
            DB[:password_reset_tokens].insert(
              account_id: account[:id],
              token: reset_token,
              expires_at: expires_at
            )
            
            # Send email (async in production)
            if Environment.email_enabled?
              Thread.new do
                EmailService.send_password_reset_email(email, reset_token)
              end
            end
          end
          
          # Always return success to prevent email enumeration
          { success: true, message: 'If an account exists with this email, you will receive reset instructions.' }
        end
        
        # Password reset confirmation
        r.post 'reset-password' do
          token = request.params['token']
          new_password = request.params['password']
          
          unless token && new_password
            response.status = 400
            next { error: 'Token and new password required' }
          end
          
          # Validate password
          unless new_password.length >= 8 && new_password =~ /[A-Z]/ && new_password =~ /[a-z]/ && new_password =~ /\d/
            response.status = 400
            next { error: 'Password must be at least 8 characters with uppercase, lowercase, and number' }
          end
          
          # Find valid reset token
          reset_record = DB[:password_reset_tokens]
            .where(token: token)
            .where(Sequel.lit('expires_at > ?', Time.now))
            .where(used: false)
            .first
          
          unless reset_record
            response.status = 400
            next { error: 'Invalid or expired reset token' }
          end
          
          # Update password
          DB.transaction do
            # Update account password
            DB[:accounts].where(id: reset_record[:account_id]).update(
              password_hash: BCrypt::Password.create(new_password),
              updated_at: Time.now
            )
            
            # Mark token as used
            DB[:password_reset_tokens].where(id: reset_record[:id]).update(used: true)
          end
          
          { success: true, message: 'Password updated successfully' }
        end
      end
      
      # Account endpoints
      r.on 'account' do
        unless authenticated?
          response.status = 401
          next { error: 'Authentication required' }
        end
        
        r.get 'info' do
          {
            id: current_user[:id],
            email: current_user[:email],
            created_at: current_user[:created_at],
            upload_limit_mb: upload_limit / 1024 / 1024
          }
        end
        
        r.get 'files' do
          files = DB[:encrypted_files]
            .where(account_id: current_user[:id])
            .order(Sequel.desc(:created_at))
            .limit(100)
            .all
          
          {
            files: files.map do |file|
              {
                file_id: file[:file_id],
                filename: file[:original_filename],
                size: file[:file_size],
                created_at: file[:created_at],
                expires_at: file[:expires_at]
              }
            end
          }
        end
      end
      
      # Upload endpoint
      r.post 'upload' do
        rate_check = RateLimiter.check_rate_limit(DB, client_ip, '/api/upload')
        unless rate_check[:allowed]
          response.status = 429
          return { error: 'Rate limit exceeded', retry_after: rate_check[:retry_after] }
        end
        
        begin
          data = request.params
          
          unless data['encrypted_data'] && data['password'] && data['mime_type']
            response.status = 400
            return { error: 'Missing required fields' }
          end
          
          password_check = Crypto.validate_password_strength(data['password'])
          unless password_check[:valid]
            response.status = 400
            return { error: password_check[:error] }
          end
          
          encrypted_data = Base64.strict_decode64(data['encrypted_data'])
          
          if encrypted_data.bytesize > upload_limit
            response.status = 400
            return { 
              error: "File too large. Max size: #{upload_limit / 1024 / 1024}MB",
              authenticated: authenticated?,
              upgrade_available: !authenticated?
            }
          end
          
          # Validate uploaded file size and type
          file_check = FileStorage.validate_file(encrypted_data, data['mime_type'], upload_limit)
          unless file_check[:valid]
            response.status = 400
            return { error: file_check[:error] }
          end
          
          file_id = Crypto.generate_file_id
          salt = Crypto.generate_salt
          password_hash = Crypto.hash_password(data['password'], salt)
          file_path = FileStorage.store_encrypted_file(file_id, encrypted_data)
          
          ttl_hours = (data['ttl_hours'] || 24).to_i
          ttl_hours = 24 if ttl_hours <= 0 || ttl_hours > 168
          expires_at = Time.now + (ttl_hours * 3600)
          
          DB[:encrypted_files].insert(
            file_id: file_id,
            password_hash: password_hash.to_s,
            salt: salt,
            file_path: file_path,
            original_filename: data['filename'],
            mime_type: data['mime_type'],
            file_size: encrypted_data.bytesize,
            encryption_iv: data['iv'] || '',
            created_at: Time.now,
            expires_at: expires_at,
            ip_address: client_ip,
            account_id: authenticated? ? current_user[:id] : nil
          )
          
          LOGGER.info "File uploaded: #{file_id} from #{client_ip} (user: #{authenticated? ? current_user[:id] : 'anonymous'})"
          
          { 
            file_id: file_id,
            expires_at: expires_at.iso8601,
            download_url: "/api/download/#{file_id}"
          }
        rescue => e
          LOGGER.error "Upload error: #{e.message}\n#{e.backtrace.join("\n")}"
          response.status = 500
          { error: 'Internal server error' }
        end
      end
      
      
                  # Streaming upload endpoints
      r.on 'streaming' do
        # Initialize streaming upload session
        r.post 'initialize' do
          begin
            # Parse JSON body
            data = JSON.parse(request.body.read) rescue request.params
            
            unless data['filename'] && data['fileSize'] && data['mimeType'] && data['password']
              response.status = 400
              next { error: 'Missing required fields: filename, fileSize, mimeType, password' }
            end
            
            # Validate password
            password_check = Crypto.validate_password_strength(data['password'])
            unless password_check[:valid]
              response.status = 400
              next { error: password_check[:error] }
            end
            
            # Check file size limit
            file_size = data['fileSize'].to_i
            max_size = authenticated? ? FileStorage::MAX_FILE_SIZE_AUTHENTICATED : FileStorage::MAX_FILE_SIZE_ANONYMOUS
            
            if file_size > max_size
              response.status = 400
              next { 
                error: "File too large. Max size: #{max_size / 1024 / 1024}MB",
                authenticated: authenticated?,
                upgrade_available: !authenticated?
              }
            end
            
            # Generate salt and hash password
            salt = Crypto.generate_salt
            password_hash = Crypto.hash_password(data['password'], salt)
            
            # Create session
            session = StreamingUpload.create_session(
              data['filename'],
              file_size,
              data['mimeType'],
              data['totalChunks'].to_i,
              data['chunkSize'].to_i,
              password_hash.to_s,
              salt,
              authenticated? ? current_user[:id] : nil
            )
            
            LOGGER.info "Streaming session created: #{session[:session_id]} for file: #{data['filename']}"
            
            session
          rescue => e
            LOGGER.error "Streaming initialize error: #{e.message}"
            LOGGER.error e.backtrace.join("\n")
            response.status = 500
            { error: "Failed to initialize streaming upload: #{e.message}" }
          end
        end
        
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

        # Finalize upload
        r.post 'finalize' do
          begin
            data = JSON.parse(request.body.read) rescue request.params
            session_id = data['session_id']
            salt = data['salt']
            
            unless session_id && salt
              response.status = 400
              next { error: 'Missing required fields: session_id, salt' }
            end
            
            file_id = StreamingUpload.finalize_session(session_id, salt)
            
            LOGGER.info "Streaming upload finalized: #{file_id}"
            
            { 
              file_id: file_id,
              share_url: "/view/#{file_id}"
            }
          rescue => e
            LOGGER.error "Finalize error: #{e.message}"
            LOGGER.error e.backtrace.join("\n")
            response.status = 500
            { error: "Failed to finalize upload: #{e.message}" }
          end
        end
        
        # Get file info
        r.get 'info', String do |file_id|
          begin
            info = StreamingUpload.get_file_info(file_id)
            info
          rescue => e
            LOGGER.error "Get file info error: #{e.message}"
            response.status = 404
            { error: 'File not found' }
          end
        end
        
        # Download chunk
        r.post 'download', String, 'chunk', Integer do |file_id, chunk_index|
          begin
            data = JSON.parse(request.body.read) rescue request.params
            password = data['password']
            
            unless password
              response.status = 401
              next { error: 'Password required' }
            end
            
            chunk_data = StreamingUpload.read_chunk(file_id, chunk_index, password)
            chunk_data
          rescue => e
            LOGGER.error "Chunk download error: #{e.message}"
            LOGGER.error e.backtrace.join("\n")
            response.status = 500
            { error: e.message }
          end
        end
      end

      
# Download endpoints
      r.on 'download', String do |file_id|
        r.get do
          begin
            file_record = DB[:encrypted_files].where(file_id: file_id).first
            
            unless file_record
              response.status = 404
              return { error: 'File not found' }
            end
            
            if file_record[:expires_at] < Time.now
              FileStorage.delete_file(file_record[:file_path])
              DB[:encrypted_files].where(id: file_record[:id]).delete
              response.status = 404
              return { error: 'File has expired' }
            end
            
            {
              file_exists: true,
              filename: file_record[:original_filename],
              mime_type: file_record[:mime_type],
              file_size: file_record[:file_size],
              expires_at: file_record[:expires_at].iso8601,
              requires_password: true
            }
          rescue => e
            LOGGER.error "File info error: #{e.message}"
            response.status = 500
            { error: 'Internal server error' }
          end
        end
        
        r.post do
          rate_check = RateLimiter.check_rate_limit(DB, client_ip, '/api/download')
          unless rate_check[:allowed]
            response.status = 429
            return { error: 'Rate limit exceeded', retry_after: rate_check[:retry_after] }
          end
          
          begin
            data = request.params
            password = data['password']
            
            unless password
              response.status = 401
              return { error: 'Password required' }
            end
            
            file_record = DB[:encrypted_files].where(file_id: file_id).first
            
            unless file_record
              response.status = 404
              return { error: 'File not found' }
            end
            
            if file_record[:expires_at] < Time.now
              FileStorage.delete_file(file_record[:file_path])
              DB[:encrypted_files].where(id: file_record[:id]).delete
              response.status = 404
              return { error: 'File has expired' }
            end
            
            unless Crypto.verify_password(password, file_record[:salt], file_record[:password_hash])
              LOGGER.warn "Invalid password attempt for file #{file_id} from #{client_ip}"
              response.status = 401
              return { error: 'Invalid password' }
            end
            
            encrypted_data = FileStorage.read_encrypted_file(file_record[:file_path])
            
            unless encrypted_data
              response.status = 404
              return { error: 'File data not found' }
            end
            
            LOGGER.info "File downloaded: #{file_id} from #{client_ip}"
            
            {
              encrypted_data: Base64.strict_encode64(encrypted_data),
              filename: file_record[:original_filename],
              mime_type: file_record[:mime_type],
              file_size: file_record[:file_size],
              iv: file_record[:encryption_iv]
            }
          rescue => e
            LOGGER.error "Download error: #{e.message}\n#{e.backtrace.join("\n")}"
            response.status = 500
            { error: 'Internal server error' }
          end
        end
      end
      
      # Cleanup
      r.delete 'cleanup' do
        begin
          FileStorage.cleanup_expired_files(DB)
          RateLimiter.cleanup_old_logs(DB)
          { message: 'Cleanup completed' }
        rescue => e
          LOGGER.error "Cleanup error: #{e.message}"
          response.status = 500
          { error: 'Cleanup failed' }
        end
      end
      
      # Info
      r.get 'info' do
        {
          service: 'Encryptor.link Backend',
          version: '2.0.0',
          features: {
            anonymous_upload: true,
            authenticated_upload: true,
            anonymous_limit_mb: FileStorage::MAX_FILE_SIZE_ANONYMOUS / 1024 / 1024,
            authenticated_limit_mb: FileStorage::MAX_FILE_SIZE_AUTHENTICATED / 1024 / 1024 / 1024
          },
          default_ttl_hours: 24,
          max_ttl_hours: 168
        }
      end
    end
  end
end
