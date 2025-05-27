class EncryptionsController < ApplicationController
  allow_unauthenticated_access

  def new
    render :new
  end

  def create
    unless params[:nonce].present?
      render json: { error: "Nonce is required" }, status: :unprocessable_entity
      return
    end

    unless params[:ttl].present? && params[:views].present?
      render json: { error: "TTL and views are required" }, status: :unprocessable_entity
      return
    end

    begin
      ttl = params[:ttl].to_i
      max_ttl = 7.days.to_i
      ttl = [ ttl, max_ttl ].min

      payload = EncryptedPayload.new(
        ciphertext: params[:ciphertext].present? ? Base64.strict_decode64(params[:ciphertext]) : "",
        nonce: Base64.strict_decode64(params[:nonce]),
        expires_at: Time.current + ttl.seconds,
        remaining_views: params[:views].to_i,
        password_protected: ActiveModel::Type::Boolean.new.cast(params[:password_protected]),
        password_salt: params[:password_salt].present? ? Base64.strict_decode64(params[:password_salt]) : nil
      )

      Rails.logger.info "Creating payload with password_protected=#{payload.password_protected?}"

      ActiveRecord::Base.transaction do
        payload.save!

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

        # Track for logged-in users if they want to
        if authenticated? && params[:track_message] == "true" && Current.encryption_key.present?
          track_user_message(payload)
        end
      end

      @payload = payload
      render json: { id: payload.id, password_protected: payload.password_protected }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Validation errors: #{e.record.errors.full_messages.join(', ')}"
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Error creating encrypted payload: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def track_user_message(payload)
    return unless payload && Current.user && Current.encryption_key

    metadata = UserMessageMetadata.new(
      user: Current.user,
      message_id: payload.id,
      file_size: calculate_total_file_size(payload),
      message_type: determine_message_type(payload),
      created_at: Time.current,
      original_expiry: payload.expires_at
    )

    # Set virtual attributes from params
    metadata.label = params[:message_label] if params[:message_label].present?
    metadata.filename = params[:primary_filename] if params[:primary_filename].present?

    # Encrypt the metadata
    metadata.encrypt_metadata(Current.encryption_key)

    metadata.save!
  rescue => e
    Rails.logger.error "Failed to track message: #{e.message}"
    # Don't fail the request if tracking fails
  end

  def calculate_total_file_size(payload)
    payload.encrypted_files.sum(:file_size)
  end

  def determine_message_type(payload)
    has_text = payload.ciphertext.present?
    has_files = payload.encrypted_files.any?

    if has_text && has_files
      "mixed"
    elsif has_files
      "file"
    else
      "text"
    end
  end
end
