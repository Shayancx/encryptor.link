class DecryptionsController < ApplicationController
  include Pagy::Backend

  def show
    # Check if we need to show an error message
    @show_error = session[:payload_expired]
    session[:payload_expired] = nil
    render :show
  end

  def data
    payload_id = params[:id]

    # Check if this payload has already been viewed in this session
    if session[:viewed_payloads]&.include?(payload_id)
      # If we've already viewed it once in this session, just return gone
      head :gone
      return
    end

    # Find the payload
    payload = EncryptedPayload.find_by(id: payload_id)

    # If it doesn't exist or is expired, return gone
    if payload.nil? || payload.expires_at < Time.current
      session[:payload_expired] = true
      head :gone
      return
    end

    # For the first view in a session, mark it as viewed but don't delete yet
    payload.with_lock do
      # Record that we've viewed this payload in this session
      session[:viewed_payloads] ||= []
      session[:viewed_payloads] << payload_id

      # Decrement the view counter
      payload.decrement!(:remaining_views)

      # If it's down to zero views, mark it for deletion after response
      session[:delete_payload] = payload_id if payload.remaining_views <= 0
    end

    # Build response data
    response_data = {
      ciphertext: Base64.strict_encode64(payload.ciphertext || ""),
      nonce: Base64.strict_encode64(payload.nonce),
      files: []
    }

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

  # Add a callback to perform deletion after the request completes
  after_action :cleanup_payload, only: [:data]

  private

  def cleanup_payload
    # If this payload was marked for deletion, delete it now
    if session[:delete_payload].present?
      payload_id = session[:delete_payload]
      session[:delete_payload] = nil

      # Run deletion in a background thread to not block the response
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            payload = EncryptedPayload.find_by(id: payload_id)
            payload&.destroy
          rescue => e
            Rails.logger.error("Error deleting payload: #{e.message}")
          end
        end
      end
    end
  end
end
