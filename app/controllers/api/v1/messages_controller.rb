module Api
  module V1
    class MessagesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def create
        payload = nil
        
        ActiveRecord::Base.transaction do
          Rails.logger.info "Starting message creation..."
          
          # Permit parameters properly
          permitted_params = params.permit(
            data: [
              :encrypted_data,
              { 
                metadata: [:expires_at, :max_views, :burn_after_reading, :has_password],
                files: [:name, :type, :size, :data, metadata: {}]
              }
            ]
          )
          
          # Extract data from permitted parameters
          message_data = permitted_params.dig(:data, :encrypted_data)
          metadata = permitted_params.dig(:data, :metadata) || {}
          files_data = permitted_params.dig(:data, :files) || []
          
          Rails.logger.info "Extracted message_data: #{message_data.inspect}"
          Rails.logger.info "Extracted metadata: #{metadata.inspect}"
          Rails.logger.info "Files count: #{files_data&.length || 0}"
          
          # Generate nonce
          nonce = SecureRandom.random_bytes(12)
          
          # Create the payload
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
          
          Rails.logger.info "Created payload with ID: #{payload.id}"
          
          # Handle files if present
          if files_data.present?
            Rails.logger.info "Processing #{files_data.length} files..."
            
            files_data.each_with_index do |file_data_params, index|
              # Convert to hash safely
              file_data = file_data_params.to_h.deep_symbolize_keys
              
              Rails.logger.info "Processing file #{index + 1}: #{file_data[:name]}"
              Rails.logger.info "File data keys: #{file_data.keys.inspect}"
              
              # Extract file information
              file_name = file_data[:name] || "unknown_file"
              file_type = file_data[:type] || 'application/octet-stream'
              file_size = file_data[:size] || 0
              
              Rails.logger.info "Creating EncryptedFile with file_name='#{file_name}', file_type='#{file_type}', file_size=#{file_size}"
              
              # Create encrypted file - explicitly set each attribute
              encrypted_file = payload.encrypted_files.new
              encrypted_file.file_name = file_name.to_s
              encrypted_file.file_type = file_type.to_s
              encrypted_file.file_size = file_size.to_i
              encrypted_file.file_metadata = (file_data[:metadata] || {}).to_json
              
              Rails.logger.info "EncryptedFile attributes before save: #{encrypted_file.attributes.inspect}"
              
              # Store the encrypted data using Active Storage BEFORE saving
              if file_data[:data].present?
                Rails.logger.info "Storing encrypted data for file: #{file_name}"
                encrypted_file.store_encrypted_data(file_data[:data])
              else
                Rails.logger.warn "No encrypted data found for file: #{file_name}"
              end
              
              # Save the encrypted file
              unless encrypted_file.save
                Rails.logger.error "Failed to save encrypted_file: #{encrypted_file.errors.full_messages}"
                Rails.logger.error "EncryptedFile attributes: #{encrypted_file.attributes.inspect}"
                raise StandardError, "Failed to save file: #{encrypted_file.errors.full_messages.join(', ')}"
              end
              
              Rails.logger.info "Successfully saved file: #{file_name} with ID: #{encrypted_file.id}"
            end
          end
          
          Rails.logger.info "Message creation successful! Payload ID: #{payload.id}"
        end
        
        # Render success response outside of transaction
        render json: { 
          id: payload.id,
          created_at: payload.created_at,
          success: true
        }, status: :created
        
      rescue StandardError => e
        Rails.logger.error("Error in MessagesController#create: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        
        # Only render error if we haven't already rendered
        unless performed?
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
