module Api
  module V1
    class MessagesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def create
        begin
          Rails.logger.info "Starting message creation..."
          
          # Extract data from nested structure
          message_data = params.dig(:data, :encrypted_data)
          metadata = params.dig(:data, :metadata) || {}
          files_data = params.dig(:data, :files) || []
          files_data = files_data.map do |file|
            file.respond_to?(:to_unsafe_h) ? file.to_unsafe_h.symbolize_keys : file.symbolize_keys
          end
          
          # Parse the encrypted data
          encrypted_data = JSON.parse(message_data) rescue message_data
          
          # Generate nonce if not provided
          nonce = if encrypted_data.is_a?(Hash) && encrypted_data['iv']
            Base64.decode64(encrypted_data['iv'])
          else
            SecureRandom.random_bytes(12)
          end
          
          # Create the payload
          payload = EncryptedPayload.create!(
            ciphertext: message_data.is_a?(String) ? message_data.encode('UTF-8').force_encoding('ASCII-8BIT') : message_data.to_json.encode('UTF-8').force_encoding('ASCII-8BIT'),
            nonce: nonce,
            expires_at: metadata[:expires_at] || 7.days.from_now,
            remaining_views: metadata[:max_views] || 1,
            burn_after_reading: metadata[:burn_after_reading] || false,
            password_protected: metadata[:has_password] || false,
            password_salt: metadata[:has_password] ? SecureRandom.random_bytes(16) : nil,
            max_views: metadata[:max_views] || 1
          )
          
          # Handle files if present
          if files_data.present?
            Rails.logger.info "Processing #{files_data.length} files..."
            
            files_data.each_with_index do |file_data, index|
              Rails.logger.info "Processing file #{index + 1}: #{file_data[:name] || file_data[:file_name]}"

              # Normalize file name in case the key differs
              name_value = file_data[:name] || file_data[:file_name] || file_data['name'] || file_data['fileName']

              # Create the encrypted file record
              encrypted_file = payload.encrypted_files.build(
                file_name: name_value,
                file_type: file_data[:type] || 'application/octet-stream',
                file_size: file_data[:size] || 0,
                file_metadata: (file_data[:metadata] || {}).to_json
              )

              # Maintain legacy :name column if it exists
              encrypted_file.name = name_value if encrypted_file.respond_to?(:name=)
              
              # Store the encrypted data using Active Storage
              if file_data[:data].present?
                encrypted_file.store_encrypted_data(file_data[:data])
              end
              
              encrypted_file.save!
            end
          end
          
          render json: { 
            id: payload.id,
            created_at: payload.created_at,
            success: true
          }, status: :created
        rescue StandardError => e
          Rails.logger.error("Error in MessagesController#create: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          render json: { error: e.message, success: false }, status: :unprocessable_entity
        end
      end
      
      def show
        payload = EncryptedPayload.find_by(id: params[:id])
        
        if payload && payload.remaining_views > 0 && !payload.expired?
          render json: {
            encrypted_data: payload.ciphertext.force_encoding('UTF-8'),
            metadata: {
              expires_at: payload.expires_at,
              max_views: payload.max_views,
              remaining_views: payload.remaining_views,
              burn_after_reading: payload.burn_after_reading,
              has_password: payload.password_protected,
              files: payload.encrypted_files.map do |file|
                {
                  id: file.id,
                  name: file.file_name,
                  type: file.file_type,
                  size: file.file_size,
                  metadata: file.file_metadata ? JSON.parse(file.file_metadata) : {}
                }
              end
            },
            deleted: false,
            success: true
          }
        else
          render json: { 
            error: "Message not found or expired", 
            deleted: true,
            success: false 
          }, status: :not_found
        end
      end
      
      def view
        payload = EncryptedPayload.find_by(id: params[:id])
        
        if payload && payload.remaining_views > 0
          payload.decrement!(:remaining_views)
          
          # Delete if no views left or burn after reading
          if payload.remaining_views <= 0 || payload.burn_after_reading
            # Also delete attached files
            payload.encrypted_files.each do |file|
              file.encrypted_blob.purge if file.encrypted_blob.attached?
            end
            payload.destroy
          end
          
          render json: { success: true }
        else
          render json: { error: "Invalid message", success: false }, status: :not_found
        end
      end
    end
  end
end
