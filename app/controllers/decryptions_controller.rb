class DecryptionsController < ApplicationController
  # Allow unauthenticated access to decryption functionality
  allow_unauthenticated_access

  def show
    # Check if we need to show an error message
    @show_error = session[:payload_expired]
    session[:payload_expired] = nil

    # Get payload_id from path
    payload_id = params[:id]
    @payload_info = get_payload_info(payload_id)

    render :show
  end

  def data
    payload_id = params[:id]

    # Find the payload
    payload = EncryptedPayload.find_by(id: payload_id)

    # If it doesn't exist or is expired, return gone
    if payload.nil? || payload.expires_at < Time.current
      Rails.logger.info("Payload #{payload_id} not found or expired")
      session[:payload_expired] = true
      head :gone
      return
    end

    # Variable to track if we should delete
    should_delete = false

    # Process the view
    payload.with_lock do
      # If there are no more views left, mark as gone
      if payload.remaining_views <= 0
        Rails.logger.info("Payload #{payload_id} has no remaining views")
        head :gone
        return
      end

      # Decrement the view counter
      payload.decrement!(:remaining_views)

      # Log the remaining views count for debugging
      Rails.logger.info("Payload #{payload_id} has #{payload.remaining_views} remaining views after decrement")

      # Check if we should delete after this request
      if payload.remaining_views <= 0
        should_delete = true
      end
    end

    # Mark for deletion in session if needed
    if should_delete
      session[:delete_payload] = payload_id
      Rails.logger.info("Marking payload #{payload_id} for deletion in session")
    end

    # Build response data
    response_data = {
      ciphertext: Base64.strict_encode64(payload.ciphertext || ""),
      nonce: Base64.strict_encode64(payload.nonce),
      password_protected: payload.password_protected,
      files: []
    }

    # Add password salt if it's password protected
    if payload.password_protected && payload.password_salt.present?
      response_data[:password_salt] = Base64.strict_encode64(payload.password_salt)
    end

    # Add files data
    payload.encrypted_files.each do |file|
      response_data[:files] << {
        id: file.id,
        data: file.file_data,
        name: file.file_name,
        type: file.file_type,
        size: file.file_size
      }
    end

    # Return the response
    render json: response_data
  end

  private

  def get_payload_info(payload_id)
    payload = EncryptedPayload.find_by(id: payload_id)
    return { exists: false } unless payload

    {
      exists: true,
      password_protected: payload.password_protected,
      expired: payload.expires_at < Time.current
    }
  end

  # Add a callback to perform deletion after the request completes
  after_action :cleanup_payload, only: [ :data ]

  def cleanup_payload
    # If this payload was marked for deletion, delete it now
    if session[:delete_payload].present?
      payload_id = session.delete(:delete_payload)

      Rails.logger.info("Running cleanup for payload #{payload_id}")

      # Always delete immediately in test environment for predictable behavior
      if Rails.env.test?
        payload = EncryptedPayload.find_by(id: payload_id)
        if payload && payload.remaining_views <= 0
          Rails.logger.info("Destroying payload #{payload_id} with 0 remaining views")
          payload.destroy
        end
      else
        # In production, use background thread
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            begin
              payload = EncryptedPayload.find_by(id: payload_id)
              if payload && payload.remaining_views <= 0
                Rails.logger.info("Destroying payload #{payload_id} with 0 remaining views")
                payload.destroy
              end
            rescue => e
              Rails.logger.error("Error in cleanup_payload: #{e.message}")
            end
          end
        end
      end
    end
  end
end
