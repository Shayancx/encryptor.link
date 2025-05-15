class EncryptionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def new
    render :new
  end

  def create
    # Create the main payload record
    payload = EncryptedPayload.new(
      ciphertext: params[:ciphertext].present? ? Base64.strict_decode64(params[:ciphertext]) : nil,
      nonce: Base64.strict_decode64(params[:nonce]),
      expires_at: Time.current + params[:ttl].to_i.seconds,
      remaining_views: params[:views].to_i
    )

    # Wrap in a transaction to ensure all files are saved or none
    ActiveRecord::Base.transaction do
      payload.save!

      # Handle multiple files if present
      if params[:files].present? && params[:files].is_a?(Array)
        params[:files].each do |file|
          encrypted_file = payload.encrypted_files.build(
            file_data: file[:data],
            file_name: file[:name],
            file_type: file[:type],
            file_size: file[:size].to_i
          )
          encrypted_file.save!
        end
      end
    end

    render json: { id: payload.id }
  rescue => e
    Rails.logger.error("Error creating encrypted payload: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
