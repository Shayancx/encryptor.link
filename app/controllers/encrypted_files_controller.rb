class EncryptedFilesController < ApplicationController
  def create
    payload_params = { payload: params[:payload] || "" }
    
    files_params = []
    if params[:files].present?
      params[:files].each do |file|
        files_params << {
          file_id: SecureRandom.uuid,
          encrypted_file: file[:encrypted_file],
          content_type: file[:content_type],
          size: file[:size]
        }
      end
    end
    
    begin
      @payload = EncryptedPayload.create_with_files(payload_params, files_params)
      render json: { 
        id: @payload.id, 
        file_ids: @payload.encrypted_files.map(&:file_id)
      }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
