module Api
  module V1
    class FilesController < ApplicationController
      skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
      
      # POST /api/v1/files
      def create
        @file = EncryptedFile.new(file_params)
        
        if @file.save
          render json: { 
            id: @file.id,
            message_id: @file.message_id,
            created_at: @file.created_at
          }, status: :created
        else
          render json: { error: @file.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/files/:id
      def show
        @file = EncryptedFile.find_by(id: params[:id])
        
        if @file
          send_data @file.file_data, 
            filename: @file.filename, 
            type: @file.content_type,
            disposition: 'attachment'
        else
          render json: { error: 'File not found' }, status: :not_found
        end
      end
      
      private
      
      def file_params
        params.permit(:file, :message_id, :metadata)
      end
    end
  end
end
