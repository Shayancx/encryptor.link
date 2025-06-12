module Api
  module V1
    class FilesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def show
        payload = EncryptedPayload.find_by(id: params[:message_id])
        
        if payload.nil?
          return render json: { error: "Message not found" }, status: :not_found
        end
        
        # Find file by name
        file_name = params[:file_name]
        file = payload.encrypted_files.find_by(file_name: file_name)
        
        if file.nil?
          return render json: { error: "File not found" }, status: :not_found
        end
        
        # Get encrypted data from Active Storage
        encrypted_data = file.get_encrypted_data
        
        if encrypted_data.nil?
          return render json: { error: "File data not found" }, status: :not_found
        end
        
        # Return the encrypted file data
        render json: {
          data: encrypted_data, # Already base64 encoded
          metadata: file.file_metadata ? JSON.parse(file.file_metadata) : {}
        }
      end
    end
  end
end
