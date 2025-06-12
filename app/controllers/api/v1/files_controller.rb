module Api
  module V1
    class FilesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def show
        payload = EncryptedPayload.find_by(id: params[:message_id])
        
        if payload.nil?
          return render json: { error: "Message not found" }, status: :not_found
        end
        
        # Find file by name - handle double encoding for special characters
        file_name = params[:file_name]
        # Try double decode first (for double encoded filenames)
        decoded_name = begin
          URI.decode_www_form_component(URI.decode_www_form_component(file_name))
        rescue
          # If double decode fails, try single decode
          begin
            URI.decode_www_form_component(file_name)
          rescue
            # If all decoding fails, use as-is
            file_name
          end
        end
        
        file = payload.encrypted_files.find_by(file_name: decoded_name)
        
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
