module Api
  module V1
    class MessagesController < ApplicationController
      protect_from_forgery with: :null_session
      
      def create
        begin
          @payload = EncryptedPayload.create_with_files(params)
          
          render json: { 
            id: @payload.id,
            created_at: @payload.created_at,
            success: true
          }, status: :created
        rescue StandardError => e
          Rails.logger.error("Error in MessagesController#create: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          render json: { error: e.message, success: false }, status: :unprocessable_entity
        end
      end
      
      def show
        @payload = EncryptedPayload.find_by(id: params[:id])
        
        if @payload
          render json: {
            encrypted_data: @payload.ciphertext, # Map ciphertext to encrypted_data in response
            metadata: {
              expires_at: @payload.expires_at,
              max_views: @payload.max_views,
              burn_after_reading: @payload.burn_after_reading,
              has_password: @payload.password_digest.present?,
              files: @payload.encrypted_files.map do |file|
                {
                  id: file.id,
                  name: file.name,
                  type: file.content_type,
                  size: file.size,
                  metadata: file.file_metadata ? (file.file_metadata.is_a?(String) ? JSON.parse(file.file_metadata) : file.file_metadata) : {}
                }
              end
            },
            success: true
          }
        else
          render json: { error: "Message not found", success: false }, status: :not_found
        end
      end
    end
  end
end
