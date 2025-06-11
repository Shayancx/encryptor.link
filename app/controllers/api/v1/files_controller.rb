module Api
  module V1
    class FilesController < ApplicationController
      def show
        payload = EncryptedPayload.find_by(id: params[:message_id])
        
        if payload.nil?
          return render json: { error: "Message not found" }, status: :not_found
        end
        
        file = payload.encrypted_files.find_by(file_id: params[:id])
        
        if file.nil?
          return render json: { error: "File not found" }, status: :not_found
        end
        
        send_data file.encrypted_file, 
                  type: file.content_type, 
                  disposition: 'attachment',
                  filename: file.file_id
      end
    end
  end
end
