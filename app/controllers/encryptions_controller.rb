class EncryptionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create ]

  def new
    render :new
  end

  def create
    # Validate required parameters
    unless params[:nonce].present?
      render json: { error: "Nonce is required" }, status: :unprocessable_entity
      return
    end

    unless params[:ttl].present? && params[:views].present?
      render json: { error: "TTL and views are required" }, status: :unprocessable_entity
      return
    end

    begin
      # Enforce maximum TTL of 7 days
      ttl = params[:ttl].to_i
      max_ttl = 7.days.to_i
      ttl = [ ttl, max_ttl ].min

      # Create the main payload record with explicit boolean conversion for password_protected
      payload = EncryptedPayload.new(
        ciphertext: params[:ciphertext].present? ? Base64.strict_decode64(params[:ciphertext]) : "",
        nonce: Base64.strict_decode64(params[:nonce]),
        expires_at: Time.current + ttl.seconds,
        remaining_views: params[:views].to_i,
        password_protected: ActiveModel::Type::Boolean.new.cast(params[:password_protected]),
        password_salt: params[:password_salt].present? ? Base64.strict_decode64(params[:password_salt]) : nil
      )

      # Log for debugging
      Rails.logger.info "Creating payload with password_protected=#{payload.password_protected?}"

      # Wrap in a transaction to ensure all files are saved or none
      ActiveRecord::Base.transaction do
        payload.save!

        # Handle multiple files if present
        if params[:files].present? && params[:files].is_a?(Array)
          params[:files].each_with_index do |file, index|
            begin
              encrypted_file = payload.encrypted_files.build(
                file_data: file[:data],
                file_name: file[:name],
                file_type: file[:type],
                file_size: file[:size].to_i
              )
              encrypted_file.save!
            rescue => file_error
              Rails.logger.error "ERROR saving file #{index + 1}: #{file_error.message}"
              raise file_error
            end
          end
        end
      end

      render json: { id: payload.id, password_protected: payload.password_protected }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Validation errors: #{e.record.errors.full_messages.join(', ')}"
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Error creating encrypted payload: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
