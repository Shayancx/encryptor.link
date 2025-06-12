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
          
          # Generate nonce - FIXED: no more IV extraction
          nonce = SecureRandom.random_bytes(12)
          
          # Create the payload - FIXED: simplified ciphertext
          payload = EncryptedPayload.create!(
            ciphertext: message_data.is_a?(String) ? message_data : message_data.to_json,
            nonce: nonce,
            expires_at: metadata[:expires_at] || 7.days.from_now,
            remaining_views: metadata[:max_views] || 1,
            burn_after_reading: metadata[:burn_after_reading] || false,
            password_protected: metadata[:has_password] || false,
            password_salt: metadata[:has_password] ? SecureRandom.random_bytes(16) : nil,
            max_views: metadata[:max_views] || 1
          )
          
          # Handle files if present - FIXED: proper file name extraction
          if files_data.present?
            Rails.logger.info "Processing #{files_data.length} files..."
            
            files_data.each_with_index do |file_data, index|
              Rails.logger.info "DEBUG: Raw file_data = #{file_data.inspect}"
              
              # FIXED: Extract filename from where frontend actually puts it
              name_value = nil
              
              # Try different possible locations for the filename
              if file_data[:metadata].present?
                name_value = file_data[:metadata]['fileName'] || file_data[:metadata][:fileName]
              end
              name_value ||= file_data[:name] || file_data['name'] || file_data[:fileName] || file_data['fileName']
              
              Rails.logger.info "DEBUG: Extracted name_value = #{name_value.inspect}"
              
              # FIXED: Extract file type from metadata
              file_type = nil
              if file_data[:metadata].present?
                file_type = file_data[:metadata]['fileType'] || file_data[:metadata][:fileType]
              end
              file_type ||= file_data[:type] || file_data['type'] || 'application/octet-stream'
              
              # FIXED: Extract file size from metadata  
              file_size = nil
              if file_data[:metadata].present?
                file_size = file_data[:metadata]['fileSize'] || file_data[:metadata][:fileSize]
              end
              file_size ||= file_data[:size] || file_data['size'] || 0
              
              Rails.logger.info "Processing file #{index + 1}: #{name_value} (#{file_type}, #{file_size} bytes)"

              # CRITICAL: Validate filename is not blank
              if name_value.blank?
                Rails.logger.error "ERROR: File name is blank for file #{index + 1}"
                Rails.logger.error "file_data keys: #{file_data.keys.inspect}"
                Rails.logger.error "metadata keys: #{file_data[:metadata]&.keys&.inspect}"
                raise StandardError, "File name is required for file #{index + 1}. Available keys: #{file_data.keys}"
              end

              # FIXED: Create encrypted file with proper attributes
              encrypted_file = payload.encrypted_files.build(
                file_name: name_value.to_s,  # CRITICAL: ensure it's a string
                file_type: file_type.to_s,
                file_size: file_size.to_i,
                file_metadata: (file_data[:metadata] || {}).to_json
              )

              Rails.logger.info "DEBUG: Built encrypted_file with file_name=#{encrypted_file.file_name.inspect}"
              
              # Store the encrypted data using Active Storage
              if file_data[:data].present?
                encrypted_file.store_encrypted_data(file_data[:data])
              end
              
              # CRITICAL: Save and check for errors
              unless encrypted_file.save
                Rails.logger.error "ERROR: Failed to save encrypted_file: #{encrypted_file.errors.full_messages}"
                raise StandardError, "Failed to save file: #{encrypted_file.errors.full_messages.join(', ')}"
              end
              
              Rails.logger.info "SUCCESS: Saved encrypted_file with ID #{encrypted_file.id}"
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
          
          if payload.remaining_views <= 0 || payload.burn_after_reading
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
